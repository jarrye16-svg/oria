-- Oria v13.1 - performance e limpeza sem fechar cadastro
-- Rode depois da 0005, se ela ja foi aplicada.

-- 1) Indices para telas mais usadas.
create index if not exists idx_entries_house_month_status
on public.entries(house_id, competence_month, status);

create index if not exists idx_entries_house_month_card
on public.entries(house_id, competence_month, card_id)
where card_id is not null;

create index if not exists idx_entries_house_month_goal
on public.entries(house_id, competence_month, goal_id)
where goal_id is not null;

create index if not exists idx_financial_cards_house_active_name
on public.financial_cards(house_id, is_active, name);

create index if not exists idx_goals_house_active_name
on public.goals(house_id, is_active, name);

-- 2) Garante que novos registros guardem criador automaticamente.
alter table if exists public.financial_cards
  alter column created_by set default auth.uid();

alter table if exists public.goals
  alter column created_by set default auth.uid();

alter table if exists public.goal_movements
  alter column created_by set default auth.uid();

-- 3) Mantem cadastro de novos usuarios permitido pelo Supabase Auth.
-- Esta migration nao bloqueia sign-up. Quem controla isso e:
-- Supabase > Authentication > Providers > Email.
