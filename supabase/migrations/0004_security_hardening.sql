-- Oria v11 - hardening para publicação web/PWA
-- Rode depois das migrations 0001, 0002 e 0003.

-- 1) RLS precisa estar ativo em todas as tabelas públicas usadas pelo app.
alter table if exists public.profiles enable row level security;
alter table if exists public.houses enable row level security;
alter table if exists public.house_members enable row level security;
alter table if exists public.entry_groups enable row level security;
alter table if exists public.entries enable row level security;
alter table if exists public.financial_cards enable row level security;
alter table if exists public.goals enable row level security;
alter table if exists public.goal_movements enable row level security;
alter table if exists public.import_batches enable row level security;
alter table if exists public.roadmap_items enable row level security;

-- 2) Evita acesso direto anônimo nas tabelas do schema public.
-- Login/cadastro continuam funcionando pelo schema auth do Supabase.
revoke all on table public.profiles from anon;
revoke all on table public.houses from anon;
revoke all on table public.house_members from anon;
revoke all on table public.entry_groups from anon;
revoke all on table public.entries from anon;
revoke all on table public.financial_cards from anon;
revoke all on table public.goals from anon;
revoke all on table public.goal_movements from anon;
revoke all on table public.import_batches from anon;
revoke all on table public.roadmap_items from anon;

-- 3) Grants mínimos para usuários autenticados. RLS ainda decide quais linhas cada usuário vê/edita.
grant select, insert, update, delete on table public.profiles to authenticated;
grant select, insert, update, delete on table public.houses to authenticated;
grant select, insert, update, delete on table public.house_members to authenticated;
grant select, insert, update, delete on table public.entry_groups to authenticated;
grant select, insert, update, delete on table public.entries to authenticated;
grant select, insert, update, delete on table public.financial_cards to authenticated;
grant select, insert, update, delete on table public.goals to authenticated;
grant select, insert, update, delete on table public.goal_movements to authenticated;
grant select, insert, update, delete on table public.import_batches to authenticated;
grant select, insert, update, delete on table public.roadmap_items to authenticated;

-- 4) Garante que funções RPC importantes não fiquem públicas para anon.
revoke all on function public.get_my_houses() from anon;
revoke all on function public.create_house_with_defaults(text) from anon;
grant execute on function public.get_my_houses() to authenticated;
grant execute on function public.create_house_with_defaults(text) to authenticated;

-- 5) Índices de suporte para RLS e filtros por casa/mês.
create index if not exists idx_house_members_user_status on public.house_members(user_id, status);
create index if not exists idx_house_members_house_user on public.house_members(house_id, user_id);
create index if not exists idx_entries_house_mode_month on public.entries(house_id, mode, competence_month);
create index if not exists idx_cards_house on public.financial_cards(house_id);
create index if not exists idx_goals_house on public.goals(house_id);
create index if not exists idx_goal_movements_house_goal on public.goal_movements(house_id, goal_id);

-- 6) Perfil: usuário só vê e edita o próprio perfil.
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles
for select
to authenticated
using (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- 7) Bloqueio básico contra valores absurdos/negativos em lançamentos financeiros.
alter table if exists public.entries
  drop constraint if exists entries_amount_positive;

alter table if exists public.entries
  add constraint entries_amount_positive
  check (amount > 0 and amount < 100000000);

alter table if exists public.financial_cards
  drop constraint if exists financial_cards_limit_positive;

alter table if exists public.financial_cards
  add constraint financial_cards_limit_positive
  check (limit_amount is null or (limit_amount >= 0 and limit_amount < 100000000));

alter table if exists public.goals
  drop constraint if exists goals_amounts_valid;

alter table if exists public.goals
  add constraint goals_amounts_valid
  check (target_amount > 0 and current_amount >= 0 and target_amount < 100000000 and current_amount < 100000000);
