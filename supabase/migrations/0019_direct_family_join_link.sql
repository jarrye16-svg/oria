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
  update public.house_join_codes
  set status = 'canceled'
  where house_id = p_house_id
    and status = 'active'
    and expires_at > now();

  v_code := lpad(floor(random() * 1000000)::int::text, 6, '0');
  v_token := encode(gen_random_bytes(24), 'hex');

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
  limit 1;

  if v_code.id is null then
    raise exception 'Link invalido, expirado ou ja usado';
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

grant execute on function public.create_house_join_code(uuid) to authenticated;
grant execute on function public.get_house_join_link_preview(text) to anon, authenticated;
grant execute on function public.accept_house_join_link(text) to authenticated;
