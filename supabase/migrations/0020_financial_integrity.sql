-- Apply in one transaction. Existing financial rows are preserved.
begin;

alter table public.goal_movements add column if not exists entry_id uuid
  references public.entries(id) on delete cascade;
create unique index if not exists goal_movements_entry_unique on public.goal_movements(entry_id)
  where entry_id is not null;

-- Only attach legacy deposits when the match is unambiguous in both directions.
with matches as (
  select m.id, e.id entry_id,
    count(*) over(partition by m.id) mc,
    count(*) over(partition by e.id) ec
  from public.goal_movements m join public.entries e
    on e.house_id=m.house_id and e.goal_id=m.goal_id and e.amount=m.amount
    and e.type='income' and e.status='paid'
    and m.kind='deposit' and m.note='Entrada direcionada: '||e.title
    and abs(extract(epoch from (m.created_at-e.created_at))) < 60
  where m.entry_id is null
)
update public.goal_movements m set entry_id=x.entry_id
from matches x where m.id=x.id and x.mc=1 and x.ec=1;

create or replace function public.apply_goal_movement()
returns trigger language plpgsql security definer set search_path=public as $$
declare
  v_old_goal uuid; v_new_goal uuid; v_old_effect numeric:=0; v_new_effect numeric:=0;
  g record; delta numeric;
begin
  if TG_OP <> 'INSERT' then
    v_old_goal:=old.goal_id;
    v_old_effect:=case when old.kind='withdraw' then -old.amount else old.amount end;
  end if;
  if TG_OP <> 'DELETE' then
    if new.amount <= 0 or new.kind not in ('deposit','withdraw') then
      raise exception 'Movimentação inválida';
    end if;
    if not exists(select 1 from public.goals where id=new.goal_id and house_id=new.house_id) then
      raise exception 'O porquinho não pertence à casa';
    end if;
    if new.entry_id is not null and not exists(select 1 from public.entries e
      where e.id=new.entry_id and e.house_id=new.house_id and e.goal_id=new.goal_id
      and e.type='income' and e.status='paid' and e.amount=new.amount) then
      raise exception 'O depósito não corresponde à entrada vinculada';
    end if;
    v_new_goal:=new.goal_id;
    v_new_effect:=case when new.kind='withdraw' then -new.amount else new.amount end;
  end if;
  for g in select id,current_amount from public.goals
    where id in(v_old_goal,v_new_goal) order by id for update
  loop
    delta:=(case when g.id=v_new_goal then v_new_effect else 0 end)
      -(case when g.id=v_old_goal then v_old_effect else 0 end);
    if g.current_amount+delta < 0 then
      raise exception 'Saldo insuficiente no porquinho para esta movimentação ou estorno';
    end if;
    update public.goals set current_amount=current_amount+delta,updated_at=now() where id=g.id;
  end loop;
  if TG_OP='DELETE' then return old; end if;
  return new;
end; $$;
drop trigger if exists goal_movements_apply on public.goal_movements;
create trigger goal_movements_apply after insert or update of amount,kind,goal_id,house_id or delete
on public.goal_movements for each row execute function public.apply_goal_movement();

create or replace function public.sync_entry_goal_movement()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  -- Ambiguous historical deposits need explicit reconciliation, never double-credit.
  if TG_OP='UPDATE' and old.type='income' and old.status='paid' and old.goal_id is not null
    and not exists(select 1 from public.goal_movements where entry_id=old.id) then
    if (new.amount,new.goal_id,new.status,new.type) is distinct from
       (old.amount,old.goal_id,old.status,old.type) then
      raise exception 'Esta entrada antiga precisa ser conciliada com o porquinho antes da alteração';
    end if;
    return new;
  end if;
  if new.type='income' and new.status='paid' and new.goal_id is not null then
    insert into public.goal_movements(house_id,goal_id,amount,kind,note,entry_id)
    values(new.house_id,new.goal_id,new.amount,'deposit','Entrada direcionada: '||new.title,new.id)
    on conflict (entry_id) where entry_id is not null do update
      set house_id=excluded.house_id,goal_id=excluded.goal_id,amount=excluded.amount,note=excluded.note;
  else
    delete from public.goal_movements where entry_id=new.id;
  end if;
  return new;
end; $$;
drop trigger if exists entries_sync_goal on public.entries;
create trigger entries_sync_goal after insert or update of amount,goal_id,status,type,title
on public.entries for each row execute function public.sync_entry_goal_movement();

create or replace function public.guard_legacy_entry_delete()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if old.type='income' and old.status='paid' and old.goal_id is not null
    and not exists(select 1 from public.goal_movements where entry_id=old.id) then
    raise exception 'Esta entrada antiga precisa ser conciliada com o porquinho antes da exclusão';
  end if;
  return old;
end; $$;
drop trigger if exists entries_guard_legacy_delete on public.entries;
create trigger entries_guard_legacy_delete before delete on public.entries
for each row execute function public.guard_legacy_entry_delete();

-- Compatibility with the published client while the update is rolling out.
create or replace function public.ignore_old_client_goal_duplicate()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.entry_id is null and new.kind='deposit' and new.note like 'Entrada direcionada: %'
    and exists(select 1 from public.goal_movements m where m.entry_id is not null
      and m.house_id=new.house_id and m.goal_id=new.goal_id and m.amount=new.amount
      and m.note=new.note and m.created_at>=now()-interval '1 minute') then
    return null;
  end if;
  return new;
end; $$;
drop trigger if exists goal_movements_old_client_guard on public.goal_movements;
create trigger goal_movements_old_client_guard before insert on public.goal_movements
for each row execute function public.ignore_old_client_goal_duplicate();

create or replace function public.keep_entry_payment_date()
returns trigger language plpgsql set search_path=public as $$
begin
  if new.status='paid' then
    if TG_OP='UPDATE' and old.status='paid' then new.paid_at:=old.paid_at;
    else new.paid_at:=coalesce(new.paid_at,now()); end if;
    new.paid_by:=coalesce(new.paid_by,auth.uid());
  else new.paid_at:=null; new.paid_by:=null;
  end if;
  return new;
end; $$;
drop trigger if exists entries_keep_payment_date on public.entries;
create trigger entries_keep_payment_date before insert or update on public.entries
for each row execute function public.keep_entry_payment_date();

create or replace function public.set_entries_paid(p_house_id uuid,p_ids uuid[],p_paid boolean)
returns void language plpgsql security invoker set search_path=public as $$
begin
  if auth.uid() is null or not public.is_house_member(p_house_id) then
    raise exception 'Sem acesso à casa';
  end if;
  if exists(select 1 from unnest(p_ids) x(id) where not exists(
    select 1 from public.entries e where e.id=x.id and e.house_id=p_house_id)) then
    raise exception 'Lançamento inválido';
  end if;
  update public.entries set status=case when p_paid then 'paid' else 'pending' end,
    paid_by=case when p_paid then auth.uid() else null end
  where house_id=p_house_id and id=any(p_ids) and status not in ('ignored','canceled');
end; $$;
revoke all on function public.set_entries_paid(uuid,uuid[],boolean) from public,anon;
grant execute on function public.set_entries_paid(uuid,uuid[],boolean) to authenticated;
notify pgrst,'reload schema';
commit;
