-- Oria v18.5 - melhora mensagens do aceite de convite
-- Rode depois da 0012.

create or replace function public.accept_house_invite(p_token text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite public.house_invites%rowtype;
  v_user_email text := lower(coalesce(auth.jwt()->>'email', ''));
begin
  if auth.uid() is null then
    raise exception 'Usuario nao autenticado';
  end if;

  select *
  into v_invite
  from public.house_invites hi
  where hi.token = trim(p_token)
    and hi.status in ('active', 'accepted')
    and hi.expires_at > now()
  limit 1;

  if v_invite.id is null then
    raise exception 'Convite invalido, cancelado ou expirado';
  end if;

  if lower(v_invite.email) <> v_user_email then
    raise exception 'Este convite e para %, mas voce entrou como %. Entre com o e-mail convidado.', v_invite.email, v_user_email;
  end if;

  insert into public.house_members (house_id, user_id, role, status)
  values (v_invite.house_id, auth.uid(), v_invite.role, 'active')
  on conflict (house_id, user_id)
  do update set role = excluded.role, status = 'active';

  update public.house_invites hi
  set status = 'accepted',
      accepted_by = auth.uid(),
      accepted_at = coalesce(hi.accepted_at, now())
  where hi.id = v_invite.id;

  return v_invite.house_id;
end;
$$;

grant execute on function public.accept_house_invite(text) to authenticated;
