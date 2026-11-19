begin;

-- Keep older installed web/PWA clients functional during rollout while routing
-- all code attempts through the same persistent account-level throttle.
create or replace function public.join_house_with_code(
  p_house_name text,
  p_code text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_result jsonb;
begin
  v_result := public.join_house_with_code_limited(p_house_name, p_code);

  if v_result ->> 'ok' = 'true' then
    return (v_result ->> 'house_id')::uuid;
  end if;

  -- Returning NULL commits the throttle counter. Raising an exception here
  -- would roll the counter back with the request transaction.
  return null;
end;
$$;

revoke all on function public.join_house_with_code(text, text)
  from public, anon, authenticated;
grant execute on function public.join_house_with_code(text, text)
  to authenticated;

notify pgrst, 'reload schema';
commit;
