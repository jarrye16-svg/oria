-- Oria v25.4.8 - corrige remocao de membros
-- Causa: a funcao antiga tentava usar status = 'removed',
-- mas a tabela house_members aceita apenas active, invited e blocked.
-- Agora remover membro bloqueia o acesso usando status = 'blocked'.

create or replace function public.get_house_members(p_house_id uuid)
returns table (
  user_id uuid,
  email text,
  full_name text,
  role text,
  status text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    hm.user_id,
    coalesce(p.email, '') as email,
    p.full_name,
    hm.role,
    hm.status
  from public.house_members hm
  left join public.profiles p on p.id = hm.user_id
  where hm.house_id = p_house_id
    and hm.status = 'active'
    and public.is_house_member(p_house_id)
  order by
    case hm.role when 'admin' then 0 else 1 end,
    coalesce(p.full_name, p.email, '') asc;
$$;

create or replace function public.remove_house_member(
  p_house_id uuid,
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_current_role text;
  v_other_admins integer;
begin
  if auth.uid() is null then
    raise exception 'Usuario nao autenticado';
  end if;

  if not public.is_house_admin(p_house_id) then
    raise exception 'Somente administrador pode remover membros';
  end if;

  if p_user_id = auth.uid() then
    raise exception 'Voce nao pode remover seu proprio acesso';
  end if;

  select hm.role
  into v_current_role
  from public.house_members hm
  where hm.house_id = p_house_id
    and hm.user_id = p_user_id
    and hm.status = 'active'
  limit 1;

  if v_current_role is null then
    raise exception 'Membro nao encontrado ou ja removido';
  end if;

  if v_current_role = 'admin' then
    select count(*)
    into v_other_admins
    from public.house_members hm
    where hm.house_id = p_house_id
      and hm.status = 'active'
      and hm.role = 'admin'
      and hm.user_id <> p_user_id;

    if v_other_admins = 0 then
      raise exception 'A casa precisa ter pelo menos um administrador ativo';
    end if;
  end if;

  update public.house_members hm
  set status = 'blocked',
      role = 'member'
  where hm.house_id = p_house_id
    and hm.user_id = p_user_id;
end;
$$;

grant execute on function public.get_house_members(uuid) to authenticated;
grant execute on function public.remove_house_member(uuid, uuid) to authenticated;
