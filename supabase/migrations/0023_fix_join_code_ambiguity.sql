begin;
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
notify pgrst,'reload schema';
commit;
