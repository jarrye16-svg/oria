begin;
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

-- Oria v25.6 - codigo temporario para entrar na familia
-- Admin gera um codigo de 6 digitos, valido por 15 minutos.
-- A pessoa cria/entra no Oria e digita o nome da familia + codigo.

create table if not exists public.house_join_codes (
  id uuid primary key default gen_random_uuid(),
  house_id uuid not null references public.houses(id) on delete cascade,
  code text not null,
  status text not null default 'active' check (status in ('active', 'used', 'expired', 'canceled')),
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  used_by uuid references auth.users(id) on delete set null,
  used_at timestamptz,
  expires_at timestamptz not null default (now() + interval '15 minutes'),
  created_at timestamptz not null default now()
);

create index if not exists idx_house_join_codes_house_status
on public.house_join_codes(house_id, status);

create index if not exists idx_house_join_codes_code_status
on public.house_join_codes(code, status);

alter table public.house_join_codes enable row level security;

drop policy if exists "house_join_codes_select_admin" on public.house_join_codes;
create policy "house_join_codes_select_admin"
on public.house_join_codes
for select
to authenticated
using (public.is_house_admin(house_id));

drop policy if exists "house_join_codes_update_admin" on public.house_join_codes;
create policy "house_join_codes_update_admin"
on public.house_join_codes
for update
to authenticated
using (public.is_house_admin(house_id))
with check (public.is_house_admin(house_id));

create or replace function public.create_house_join_code(p_house_id uuid)
returns table (
  code text,
  house_name text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_house_name text;
begin
  if auth.uid() is null then
    raise exception 'Usuario nao autenticado';
  end if;

  if not public.is_house_admin(p_house_id) then
    raise exception 'Somente administrador pode gerar codigo de entrada';
  end if;

  select h.name
  into v_house_name
  from public.houses h
  where h.id = p_house_id;

  if v_house_name is null then
    raise exception 'Familia nao encontrada';
  end if;

  perform 1 from public.houses h where h.id=p_house_id for update;
  update public.house_join_codes as hjc
  set status = 'canceled'
  where hjc.house_id = p_house_id
    and hjc.status = 'active'
    and hjc.expires_at > now();

  -- 6 digitos, evitando zeros a esquerda perdidos.
  v_code := lpad(floor(random() * 1000000)::int::text, 6, '0');

  insert into public.house_join_codes (house_id, code)
  values (p_house_id, v_code);

  return query
  select
    v_code,
    v_house_name,
    now() + interval '15 minutes';
end;
$$;

create or replace function public.join_house_with_code(
  p_house_name text,
  p_code text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code public.house_join_codes%rowtype;
  v_house_id uuid;
  v_house_name text := lower(trim(p_house_name));
  v_clean_code text := regexp_replace(coalesce(p_code, ''), '[^0-9]', '', 'g');
begin
  if auth.uid() is null then
    raise exception 'Usuario nao autenticado';
  end if;

  if length(v_house_name) < 3 then
    raise exception 'Informe o nome da familia';
  end if;

  if length(v_clean_code) <> 6 then
    raise exception 'Codigo precisa ter 6 digitos';
  end if;

  select hjc.*
  into v_code
  from public.house_join_codes hjc
  join public.houses h on h.id = hjc.house_id
  where hjc.code = v_clean_code
    and hjc.status = 'active'
    and hjc.expires_at > now()
    and lower(trim(h.name)) = v_house_name
  order by hjc.created_at desc
  limit 1 for update of hjc;

  if v_code.id is null then
    raise exception 'Codigo invalido, expirado ou familia diferente';
  end if;

  v_house_id := v_code.house_id;

  insert into public.house_members (house_id, user_id, role, status)
  values (v_house_id, auth.uid(), 'member', 'active')
  on conflict (house_id, user_id)
  do update set role = case when public.house_members.status='active' and public.house_members.role='admin' then 'admin' else 'member' end, status = 'active';

  update public.house_join_codes
  set status = 'used',
      used_by = auth.uid(),
      used_at = now()
  where id = v_code.id;

  return v_house_id;
end;
$$;

grant select, update on table public.house_join_codes to authenticated;
grant execute on function public.create_house_join_code(uuid) to authenticated;
grant execute on function public.join_house_with_code(text, text) to authenticated;

drop function if exists public.create_house_join_code(uuid);
-- Oria v25.6.1 - link direto para entrar na familia
-- Link nao fica preso a e-mail, vale 15 minutos e e de uso unico.
-- Fluxo:
-- Admin gera link em Membros > Entrada por link.
-- Pessoa abre o link, entra/cria acesso e confirma entrada na familia.

alter table public.house_join_codes
add column if not exists token text;

create unique index if not exists idx_house_join_codes_token_unique
on public.house_join_codes(token)
where token is not null;

create index if not exists idx_house_join_codes_token_status
on public.house_join_codes(token, status)
where token is not null;

create or replace function public.create_house_join_code(p_house_id uuid)
returns table (
  code text,
  token text,
  house_name text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_token text;
  v_house_name text;
  v_expires_at timestamptz := now() + interval '15 minutes';
begin
  if auth.uid() is null then
    raise exception 'Usuario nao autenticado';
  end if;

  if not public.is_house_admin(p_house_id) then
    raise exception 'Somente administrador pode gerar link de entrada';
  end if;

  select h.name
  into v_house_name
  from public.houses h
  where h.id = p_house_id;

  if v_house_name is null then
    raise exception 'Familia nao encontrada';
  end if;

  -- Cancela codigos/links ativos anteriores para a mesma familia.
  perform 1 from public.houses h where h.id=p_house_id for update;
  update public.house_join_codes as hjc
  set status = 'canceled'
  where hjc.house_id = p_house_id
    and hjc.status = 'active'
    and hjc.expires_at > now();

  v_code := lpad(floor(random() * 1000000)::int::text, 6, '0');
  v_token := replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');

  insert into public.house_join_codes (house_id, code, token, expires_at)
  values (p_house_id, v_code, v_token, v_expires_at);

  return query
  select
    v_code,
    v_token,
    v_house_name,
    v_expires_at;
end;
$$;

create or replace function public.get_house_join_link_preview(p_token text)
returns table (
  house_name text,
  status text,
  expires_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    h.name as house_name,
    case
      when hjc.status <> 'active' then hjc.status
      when hjc.expires_at <= now() then 'expired'
      else hjc.status
    end as status,
    hjc.expires_at
  from public.house_join_codes hjc
  join public.houses h on h.id = hjc.house_id
  where hjc.token = trim(p_token)
  limit 1;
$$;

create or replace function public.accept_house_join_link(p_token text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code public.house_join_codes%rowtype;
  v_house_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuario nao autenticado';
  end if;

  select *
  into v_code
  from public.house_join_codes hjc
  where hjc.token = trim(p_token)
    and hjc.status = 'active'
    and hjc.expires_at > now()
  limit 1 for update;

  if v_code.id is null then
    raise exception 'Link invalido, expirado ou ja usado';
  end if;

  v_house_id := v_code.house_id;

  insert into public.house_members (house_id, user_id, role, status)
  values (v_house_id, auth.uid(), 'member', 'active')
  on conflict (house_id, user_id)
  do update set role = case when public.house_members.status='active' and public.house_members.role='admin' then 'admin' else 'member' end, status = 'active';

  update public.house_join_codes
  set status = 'used',
      used_by = auth.uid(),
      used_at = now()
  where id = v_code.id;

  return v_house_id;
end;
$$;

grant execute on function public.create_house_join_code(uuid) to authenticated;
grant execute on function public.get_house_join_link_preview(text) to anon, authenticated;
grant execute on function public.accept_house_join_link(text) to authenticated;

revoke all on function public.create_house_join_code(uuid) from public,anon;
revoke all on function public.join_house_with_code(text,text) from public,anon;
revoke all on function public.accept_house_join_link(text) from public,anon;
revoke all on function public.get_house_join_link_preview(text) from public;
notify pgrst, 'reload schema';
commit;
