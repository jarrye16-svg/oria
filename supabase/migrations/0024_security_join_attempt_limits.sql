begin;

-- Prevent future functions created by the migration owner from inheriting the
-- default PUBLIC execute grant. Functions exposed to the app are granted below.
alter default privileges revoke execute on functions from public;
alter default privileges in schema public
  revoke execute on functions from anon, authenticated;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists private.house_join_attempts (
  user_id uuid primary key references auth.users(id) on delete cascade,
  window_started_at timestamptz not null,
  attempt_count smallint not null default 0 check (attempt_count >= 0),
  blocked_until timestamptz
);
alter table private.house_join_attempts enable row level security;
revoke all on table private.house_join_attempts from public, anon, authenticated;

-- Uniform numeric digits derived from a cryptographically random UUID.
create or replace function private.generate_secure_numeric_code(p_length integer)
returns text
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_random_bytes bytea;
  v_byte integer;
  v_index integer;
  v_code text := '';
begin
  if p_length < 1 or p_length > 12 then
    raise exception 'Tamanho de código inválido';
  end if;

  while pg_catalog.length(v_code) < p_length loop
    v_random_bytes := pg_catalog.decode(
      pg_catalog.replace(pg_catalog.gen_random_uuid()::text, '-', ''),
      'hex'
    );

    for v_index in 0..15 loop
      v_byte := pg_catalog.get_byte(v_random_bytes, v_index);
      -- Reject 250..255 so each decimal digit has the same probability.
      if v_byte < 250 then
        v_code := v_code || (v_byte % 10)::text;
        exit when pg_catalog.length(v_code) = p_length;
      end if;
    end loop;
  end loop;

  return v_code;
end;
$$;
revoke all on function private.generate_secure_numeric_code(integer)
  from public, anon, authenticated;

-- New numeric invitations are 8 digits. Existing 6-digit invitations continue
-- to work until their normal 15-minute expiration.
create or replace function public.create_house_join_code(p_house_id uuid)
returns table (
  code text,
  token text,
  house_name text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_code text;
  v_token text;
  v_house_name text;
  v_expires_at timestamptz := pg_catalog.now() + interval '15 minutes';
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;

  if not public.is_house_admin(p_house_id) then
    raise exception 'Somente administrador pode gerar link de entrada';
  end if;

  select h.name
  into v_house_name
  from public.houses h
  where h.id = p_house_id;

  if v_house_name is null then
    raise exception 'Família não encontrada';
  end if;

  perform 1 from public.houses h where h.id = p_house_id for update;
  update public.house_join_codes hjc
  set status = 'canceled'
  where hjc.house_id = p_house_id
    and hjc.status = 'active'
    and hjc.expires_at > pg_catalog.now();

  v_code := private.generate_secure_numeric_code(8);
  v_token := pg_catalog.replace(pg_catalog.gen_random_uuid()::text, '-', '')
    || pg_catalog.replace(pg_catalog.gen_random_uuid()::text, '-', '');

  insert into public.house_join_codes (house_id, code, token, expires_at)
  values (p_house_id, v_code, v_token, v_expires_at);

  return query select v_code, v_token, v_house_name, v_expires_at;
end;
$$;

-- Count failed attempts per authenticated account. A failure is returned as a
-- normal result so PostgreSQL commits the counter instead of rolling it back.
create or replace function public.join_house_with_code_limited(
  p_house_name text,
  p_code text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_house_name text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_house_name, '')));
  v_clean_code text := pg_catalog.regexp_replace(coalesce(p_code, ''), '[^0-9]', '', 'g');
  v_now timestamptz := pg_catalog.clock_timestamp();
  v_blocked_until timestamptz;
  v_attempt_count integer;
  v_join_code public.house_join_codes%rowtype;
begin
  if v_user_id is null then
    return pg_catalog.jsonb_build_object('ok', false, 'code', 'authentication_required');
  end if;

  select a.blocked_until
  into v_blocked_until
  from private.house_join_attempts a
  where a.user_id = v_user_id
  for update;

  if v_blocked_until is not null and v_blocked_until > v_now then
    return pg_catalog.jsonb_build_object(
      'ok', false,
      'code', 'rate_limited',
      'retry_after_seconds', greatest(1, ceil(extract(epoch from (v_blocked_until - v_now)))::integer)
    );
  end if;

  if pg_catalog.length(v_house_name) < 3
    or pg_catalog.length(v_house_name) > 120
    or pg_catalog.length(v_clean_code) not in (6, 8) then
    return pg_catalog.jsonb_build_object('ok', false, 'code', 'invalid_input');
  end if;

  select hjc.*
  into v_join_code
  from public.house_join_codes hjc
  join public.houses h on h.id = hjc.house_id
  where hjc.code = v_clean_code
    and hjc.status = 'active'
    and hjc.expires_at > v_now
    and pg_catalog.lower(pg_catalog.btrim(h.name)) = v_house_name
  order by hjc.created_at desc
  limit 1
  for update of hjc;

  if v_join_code.id is null then
    insert into private.house_join_attempts as a (
      user_id, window_started_at, attempt_count, blocked_until
    ) values (v_user_id, v_now, 1, null)
    on conflict (user_id) do update
      set window_started_at = case
            when a.window_started_at <= v_now - interval '15 minutes'
              or (a.blocked_until is not null and a.blocked_until <= v_now)
              then v_now
            else a.window_started_at
          end,
          attempt_count = case
            when a.window_started_at <= v_now - interval '15 minutes'
              or (a.blocked_until is not null and a.blocked_until <= v_now)
              then 1
            else a.attempt_count + 1
          end,
          blocked_until = case
            when a.blocked_until is not null and a.blocked_until <= v_now then null
            else a.blocked_until
          end
    returning attempt_count into v_attempt_count;

    if v_attempt_count >= 5 then
      v_blocked_until := v_now + interval '15 minutes';
      update private.house_join_attempts
      set blocked_until = v_blocked_until
      where user_id = v_user_id;

      return pg_catalog.jsonb_build_object(
        'ok', false,
        'code', 'rate_limited',
        'retry_after_seconds', 900
      );
    end if;

    return pg_catalog.jsonb_build_object(
      'ok', false,
      'code', 'invalid_code',
      'attempts_remaining', 5 - v_attempt_count
    );
  end if;

  insert into public.house_members (house_id, user_id, role, status)
  values (v_join_code.house_id, v_user_id, 'member', 'active')
  on conflict (house_id, user_id)
  do update set
    role = case
      when public.house_members.status = 'active' and public.house_members.role = 'admin'
        then 'admin'
      else 'member'
    end,
    status = 'active';

  update public.house_join_codes
  set status = 'used',
      used_by = v_user_id,
      used_at = v_now
  where id = v_join_code.id;

  delete from private.house_join_attempts where user_id = v_user_id;
  return pg_catalog.jsonb_build_object('ok', true, 'house_id', v_join_code.house_id);
end;
$$;

-- No direct access to invitation secrets or throttle state. RPCs are an
-- explicit allowlist; no function in public is callable by default roles.
revoke all on table public.house_join_codes from public, anon, authenticated;
revoke execute on function public.join_house_with_code(text, text)
  from public, anon, authenticated;
revoke execute on all functions in schema public from public, anon, authenticated;

grant execute on function public.is_house_member(uuid) to authenticated;
grant execute on function public.is_house_admin(uuid) to authenticated;
grant execute on function public.get_my_houses() to authenticated;
grant execute on function public.create_house_with_defaults(text) to authenticated;
grant execute on function public.create_house_invite(uuid, text, text) to authenticated;
grant execute on function public.accept_house_invite(text) to authenticated;
grant execute on function public.get_house_members(uuid) to authenticated;
grant execute on function public.update_house_member_role(uuid, uuid, text) to authenticated;
grant execute on function public.remove_house_member(uuid, uuid) to authenticated;
grant execute on function public.get_house_invite_preview(text) to authenticated;
grant execute on function public.create_house_join_code(uuid) to authenticated;
grant execute on function public.join_house_with_code_limited(text, text) to authenticated;
grant execute on function public.get_house_join_link_preview(text) to anon, authenticated;
grant execute on function public.accept_house_join_link(text) to authenticated;
grant execute on function public.set_entries_paid(uuid, uuid[], boolean) to authenticated;
grant execute on function public.restore_entries(uuid, jsonb) to authenticated;

notify pgrst, 'reload schema';
commit;
