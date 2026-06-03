-- Oria v18.6 - protecao de administrador da casa
-- Rode depois da 0013.

create or replace function public.update_house_member_role(
  p_house_id uuid,
  p_user_id uuid,
  p_role text
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
    raise exception 'Somente administrador pode alterar membros';
  end if;

  if p_role not in ('admin', 'member') then
    raise exception 'Perfil invalido';
  end if;

  select hm.role
  into v_current_role
  from public.house_members hm
  where hm.house_id = p_house_id
    and hm.user_id = p_user_id
    and hm.status = 'active'
  limit 1;

  if v_current_role is null then
    raise exception 'Membro nao encontrado';
  end if;

  if p_user_id = auth.uid() and v_current_role = 'admin' and p_role = 'member' then
    raise exception 'Voce nao pode remover seu proprio perfil de administrador';
  end if;

  if v_current_role = 'admin' and p_role = 'member' then
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
  set role = p_role,
      status = 'active'
  where hm.house_id = p_house_id
    and hm.user_id = p_user_id;
end;
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
    raise exception 'Membro nao encontrado';
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
  set status = 'removed'
  where hm.house_id = p_house_id
    and hm.user_id = p_user_id;
end;
$$;

grant execute on function public.update_house_member_role(uuid, uuid, text) to authenticated;
grant execute on function public.remove_house_member(uuid, uuid) to authenticated;
