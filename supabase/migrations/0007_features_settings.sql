-- Oria v14 - ajustes funcionais
-- Rode depois da 0006.

-- Permite ao admin editar categorias pelo app.
-- Politicas antigas ja permitem admin inserir/editar/deletar entry_groups.

-- Quem esta na casa pode apagar lancamentos, conforme regra do app familiar.
drop policy if exists "entries_delete_admin" on public.entries;
drop policy if exists "entries_delete_member" on public.entries;

create policy "entries_delete_member"
on public.entries
for delete
to authenticated
using (public.is_house_member(house_id));

-- Indices para relatorios e geracao do proximo mes.
create index if not exists idx_entries_house_month_recurring
on public.entries(house_id, competence_month, is_recurring);

create index if not exists idx_entries_house_month_group
on public.entries(house_id, competence_month, group_id);

create index if not exists idx_entries_house_month_mode
on public.entries(house_id, competence_month, mode);
