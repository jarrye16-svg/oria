-- Oria v16 - membros e convites
-- Rode depois da 0008.

create table if not exists public.house_invites (
  id uuid primary key default gen_random_uuid(),
  house_id uuid not null references public.houses(id) on delete cascade,
  email text not null,
  role text not null default 'member' check (role in ('admin', 'member')),
  token text not null unique default encode(gen_random_bytes(24), 'hex'),
  status text not null default 'active' check (status in ('active', 'accepted', 'canceled')),
  invited_by uuid references auth.users(id) on delete set null default auth.uid(),
  accepted_by uuid references auth.users(id) on delete set null,
  accepted_at timestamptz,
  expires_at timestamptz not null default (now() + interval '14 days'),
  created_at timestamptz not null default now()
);

create index if not exists idx_house_invites_house_status
on public.house_invites(house_id, status);

create index if not exists idx_house_invites_email_status
on public.house_invites(lower(email), status);

create index if not exists idx_house_invites_token
on public.house_invites(token);

alter table public.house_invites enable row level security;

drop policy if exists "house_invites_select_admin" on public.house_invites;
create policy "house_invites_select_admin"
on public.house_invites
for select
to authenticated
using (public.is_house_admin(house_id));

drop policy if exists "house_invites_insert_admin" on public.house_invites;
create policy "house_invites_insert_admin"
on public.house_invites
for insert
to authenticated
with check (public.is_house_admin(house_id));

drop policy if exists "house_invites_update_admin" on public.house_invites;
create policy "house_invites_update_admin"
on public.house_invites
for update
to authenticated
using (public.is_house_admin(house_id))
with check (public.is_house_admin(house_id));

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

  if not public.is_house_admin(p_house_id) then
    raise exception 'Somente administrador pode convidar membros';
  end if;

  if v_email = '' or position('@' in v_email) = 0 then
    raise exception 'E-mail invalido';
  end if;

  if v_role not in ('admin', 'member') then
    v_role := 'member';
  end if;

  -- Cancela convites ativos anteriores para o mesmo e-mail/casa.
  update public.house_invites
  set status = 'canceled'
  where house_id = p_house_id
    and lower(email) = v_email
    and status = 'active';

  insert into public.house_invites (house_id, email, role)
  values (p_house_id, v_email, v_role)
  returning house_invites.token, house_invites.expires_at
  into v_token, v_expires_at;

  return query select v_token, v_email, v_role, v_expires_at;
end;
$$;

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
  from public.house_invites
  where token = trim(p_token)
    and status in ('active', 'accepted')
    and expires_at > now()
  limit 1;

  if v_invite.id is null then
    raise exception 'Convite invalido ou expirado';
  end if;

  if lower(v_invite.email) <> v_user_email then
    raise exception 'Este convite pertence a outro e-mail';
  end if;

  insert into public.house_members (house_id, user_id, role, status)
  values (v_invite.house_id, auth.uid(), v_invite.role, 'active')
  on conflict (house_id, user_id)
  do update set role = excluded.role, status = 'active';

  update public.house_invites
  set status = 'accepted',
      accepted_by = auth.uid(),
      accepted_at = coalesce(accepted_at, now())
  where id = v_invite.id;

  return v_invite.house_id;
end;
$$;

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
    and public.is_house_member(p_house_id)
  order by
    case hm.role when 'admin' then 0 else 1 end,
    coalesce(p.full_name, p.email, '') asc;
$$;

grant select, insert, update on table public.house_invites to authenticated;
grant execute on function public.create_house_invite(uuid, text, text) to authenticated;
grant execute on function public.accept_house_invite(text) to authenticated;
grant execute on function public.get_house_members(uuid) to authenticated;
