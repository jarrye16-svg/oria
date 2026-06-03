-- Oria v13 - revisao para uso com dados pessoais
-- Rode depois das migrations 0001 a 0004.

-- 1) Remove funcao de demo que continha exemplos sensiveis/antigos.
revoke all on function public.seed_oria_spreadsheet_demo(uuid) from anon;
revoke all on function public.seed_oria_spreadsheet_demo(uuid) from authenticated;
drop function if exists public.seed_oria_spreadsheet_demo(uuid);

-- 2) Reforco de RLS. Service role ainda bypassa por design do Supabase.
alter table if exists public.profiles force row level security;
alter table if exists public.houses force row level security;
alter table if exists public.house_members force row level security;
alter table if exists public.entry_groups force row level security;
alter table if exists public.entries force row level security;
alter table if exists public.financial_cards force row level security;
alter table if exists public.goals force row level security;
alter table if exists public.goal_movements force row level security;
alter table if exists public.import_batches force row level security;
alter table if exists public.roadmap_items force row level security;

-- 3) Auditoria minima: garantir created_by no que o app cria direto.
alter table if exists public.financial_cards
  alter column created_by set default auth.uid();

alter table if exists public.goals
  alter column created_by set default auth.uid();

alter table if exists public.goal_movements
  alter column created_by set default auth.uid();

-- 4) Limites de texto para evitar payloads enormes.
alter table if exists public.entries
  drop constraint if exists entries_text_size_guard;

alter table if exists public.entries
  add constraint entries_text_size_guard
  check (
    char_length(title) <= 120
    and (notes is null or char_length(notes) <= 2000)
    and (responsible is null or char_length(responsible) <= 120)
  );

alter table if exists public.financial_cards
  drop constraint if exists financial_cards_text_size_guard;

alter table if exists public.financial_cards
  add constraint financial_cards_text_size_guard
  check (
    char_length(name) <= 80
    and char_length(owner_name) <= 80
    and char_length(bank_name) <= 80
  );

alter table if exists public.goals
  drop constraint if exists goals_text_size_guard;

alter table if exists public.goals
  add constraint goals_text_size_guard
  check (
    char_length(name) <= 100
    and char_length(owner_name) <= 80
  );

alter table if exists public.goal_movements
  drop constraint if exists goal_movements_text_size_guard;

alter table if exists public.goal_movements
  add constraint goal_movements_text_size_guard
  check (note is null or char_length(note) <= 1000);

-- 5) Bloqueia status desconhecido e modes fora do app atual.
alter table if exists public.entries
  drop constraint if exists entries_mode_check;

alter table if exists public.entries
  add constraint entries_mode_check
  check (
    mode is null or mode in ('income', 'fixed_expense', 'card_invoice', 'goal_contribution')
  );

-- 6) Permite apagar lancamentos para qualquer membro ativo da casa.
-- Para casal/familia pequena, isso bate com a regra do app: quem esta no grupo pode editar/apagar.
drop policy if exists "entries_delete_admin" on public.entries;
drop policy if exists "entries_delete_member" on public.entries;

create policy "entries_delete_member"
on public.entries
for delete
to authenticated
using (public.is_house_member(house_id));
