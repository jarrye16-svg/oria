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

  update public.house_join_codes
  set status = 'canceled'
  where house_id = p_house_id
    and status = 'active'
    and expires_at > now();

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
  limit 1;

  if v_code.id is null then
    raise exception 'Codigo invalido, expirado ou familia diferente';
  end if;

  v_house_id := v_code.house_id;

  insert into public.house_members (house_id, user_id, role, status)
  values (v_house_id, auth.uid(), 'member', 'active')
  on conflict (house_id, user_id)
  do update set role = 'member', status = 'active';

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
