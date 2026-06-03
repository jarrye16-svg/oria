-- Oria v18 - nucleo profissional
-- Rode depois da 0009.

-- Permissoes de membros
create or replace function public.update_house_member_role(
  p_house_id uuid,
  p_user_id uuid,
  p_role text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Usuario nao autenticado';
  end if;

  if not public.is_house_admin(p_house_id) then
    raise exception 'Somente administrador pode alterar membros';
  end if;

  if p_role not in ('admin', 'member') then
    raise exception 'Perfil invalido';
  end if;

  update public.house_members
  set role = p_role,
      status = 'active'
  where house_id = p_house_id
    and user_id = p_user_id;

  if not found then
    raise exception 'Membro nao encontrado';
  end if;
end;
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

  update public.house_members
  set status = 'removed'
  where house_id = p_house_id
    and user_id = p_user_id;

  if not found then
    raise exception 'Membro nao encontrado';
  end if;
end;
$$;

grant execute on function public.update_house_member_role(uuid, uuid, text) to authenticated;
grant execute on function public.remove_house_member(uuid, uuid) to authenticated;

-- Performance para importacao/backup e detalhes por cartao.
create index if not exists idx_entries_house_mode_card_month
on public.entries(house_id, mode, card_id, competence_month);

create index if not exists idx_entries_house_group_month
on public.entries(house_id, group_id, competence_month);
