-- Oria v19 - convite com confirmacao de ingresso
-- Rode depois da 0014.

create or replace function public.get_house_invite_preview(p_token text)
returns table (
  house_name text,
  email text,
  status text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Usuario nao autenticado';
  end if;

  return query
  select
    h.name as house_name,
    hi.email,
    hi.status,
    hi.expires_at
  from public.house_invites hi
  join public.houses h on h.id = hi.house_id
  where hi.token = trim(p_token)
    and hi.status in ('active', 'accepted')
    and hi.expires_at > now()
  limit 1;

  if not found then
    raise exception 'Convite invalido, cancelado ou expirado';
  end if;
end;
$$;

grant execute on function public.get_house_invite_preview(text) to authenticated;
