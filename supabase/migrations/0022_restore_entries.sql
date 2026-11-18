begin;
create or replace function public.restore_entries(p_house_id uuid,p_rows jsonb)
returns void language plpgsql security invoker set search_path=public as $$
begin
  if auth.uid() is null or not public.is_house_member(p_house_id) then
    raise exception 'Sem acesso à casa';
  end if;
  if jsonb_typeof(p_rows) is distinct from 'array' then raise exception 'CSV inválido'; end if;
  if jsonb_array_length(p_rows)>5000 or jsonb_array_length(p_rows)=0 then raise exception 'Quantidade inválida'; end if;
  if exists(select 1 from jsonb_array_elements(p_rows) x where
    (x->>'house_id')::uuid is distinct from p_house_id or x->>'id' is null
    or coalesce(trim(x->>'title'),'')='' or (x->>'amount')::numeric<0
    or (x->>'amount')::numeric>9999999999.99
    or x->>'type' not in ('income','expense')
    or x->>'status' not in ('pending','paid','partial','ignored','canceled')) then
    raise exception 'Lançamento inválido ou de outra casa';
  end if;
  if (select count(distinct x->>'id') from jsonb_array_elements(p_rows) x)<>jsonb_array_length(p_rows) then
    raise exception 'CSV com identificadores repetidos';
  end if;
  if exists(select 1 from jsonb_array_elements(p_rows) x where
    (x->>'goal_id' is not null and not exists(select 1 from public.goals g where g.id=(x->>'goal_id')::uuid and g.house_id=p_house_id))
    or (x->>'card_id' is not null and not exists(select 1 from public.financial_cards c where c.id=(x->>'card_id')::uuid and c.house_id=p_house_id))
    or (x->>'group_id' is not null and not exists(select 1 from public.entry_groups g where g.id=(x->>'group_id')::uuid and g.house_id=p_house_id))) then
    raise exception 'Cartão, categoria ou porquinho não encontrado nesta casa';
  end if;
  insert into public.entries(id,house_id,group_id,title,amount,type,status,competence_month,
    due_date,responsible,notes,is_recurring,mode,card_id,goal_id,paid_at)
  select x.id,p_house_id,x.group_id,x.title,x.amount,x.type,x.status,x.competence_month,
    x.due_date,x.responsible,x.notes,x.is_recurring,x.mode,x.card_id,x.goal_id,x.paid_at
  from jsonb_to_recordset(p_rows) as x(id uuid,group_id uuid,title text,amount numeric,type text,status text,
    competence_month date,due_date date,responsible text,notes text,is_recurring boolean,mode text,
    card_id uuid,goal_id uuid,paid_at timestamptz)
  on conflict(id) do update set group_id=excluded.group_id,title=excluded.title,amount=excluded.amount,
    type=excluded.type,status=excluded.status,competence_month=excluded.competence_month,
    due_date=excluded.due_date,responsible=excluded.responsible,notes=excluded.notes,
    is_recurring=excluded.is_recurring,mode=excluded.mode,card_id=excluded.card_id,goal_id=excluded.goal_id;
end; $$;
revoke all on function public.restore_entries(uuid,jsonb) from public,anon;
grant execute on function public.restore_entries(uuid,jsonb) to authenticated;
notify pgrst,'reload schema';
commit;
