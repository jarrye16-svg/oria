-- Oria v15 - revisao fina de performance/auditoria
-- Rode depois da 0007.

-- Indice para backup/exportacao por casa.
create index if not exists idx_entries_house_competence_due
on public.entries(house_id, competence_month desc, due_date asc);

-- Garante auditoria minima de criacao quando o app inserir dados.
alter table if exists public.entries
  alter column created_by set default auth.uid();

alter table if exists public.import_batches
  alter column created_by set default auth.uid();

alter table if exists public.roadmap_items
  alter column created_by set default auth.uid();

-- Evita categorias com nome vazio/absurdo.
alter table if exists public.entry_groups
  drop constraint if exists entry_groups_name_guard;

alter table if exists public.entry_groups
  add constraint entry_groups_name_guard
  check (char_length(trim(name)) between 2 and 60);

-- Evita nomes de casas gigantes.
alter table if exists public.houses
  drop constraint if exists houses_name_guard;

alter table if exists public.houses
  add constraint houses_name_guard
  check (char_length(trim(name)) between 2 and 80);
