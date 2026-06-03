-- Oria v18.2 - diagnostico e reforco de convites
-- Rode depois da 0010 se o convite continuar falhando.

create or replace function public.create_house_invite(
  p_house_id uuid,
  p_email text,
  p_role text default 'member'
)
returns table (
  token text,
  email text,
  role text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text := lower(trim(p_email));
  v_role text := coalesce(nullif(trim(p_role), ''), 'member');
  v_token text;
  v_expires_at timestamptz;
begin
  if auth.uid() is null then
    raise exception 'Usuario nao autenticado';
  end if;

  if not exists (
    select 1
    from public.house_members hm
    where hm.house_id = p_house_id
      and hm.user_id = auth.uid()
      and hm.role = 'admin'
      and hm.status = 'active'
  ) then
    raise exception 'Somente administrador pode convidar membros. user=%, house=%', auth.uid(), p_house_id;
  end if;

  if v_email = '' or position('@' in v_email) = 0 then
    raise exception 'E-mail invalido: %', p_email;
  end if;

  if v_role not in ('admin', 'member') then
    v_role := 'member';
  end if;

  update public.house_invites
  set status = 'canceled'
  where house_id = p_house_id
    and lower(email) = v_email
    and status = 'active';

  insert into public.house_invites (house_id, email, role, invited_by)
  values (p_house_id, v_email, v_role, auth.uid())
  returning house_invites.token, house_invites.expires_at
  into v_token, v_expires_at;

  return query select v_token, v_email, v_role, v_expires_at;
end;
$$;

grant execute on function public.create_house_invite(uuid, text, text) to authenticated;
