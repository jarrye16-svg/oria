-- Oria v2: Cartões, metas/porquinhos e classificação de lançamentos

alter table public.entries
  add column if not exists mode text,
  add column if not exists card_id uuid,
  add column if not exists goal_id uuid;

update public.entries e
set mode = case
  when e.type = 'income' then 'income'
  when lower(coalesce(g.name, '')) like '%cart%' then 'card_invoice'
  when lower(coalesce(g.name, '')) like '%moto%' or lower(coalesce(g.name, '')) like '%financi%' then 'financing'
  when lower(coalesce(g.name, '')) like '%terce%' then 'third_party'
  else 'fixed_expense'
end
from public.entry_groups g
where e.group_id = g.id
  and e.mode is null;

update public.entries
set mode = case when type = 'income' then 'income' else 'fixed_expense' end
where mode is null;

create table if not exists public.financial_cards (
  id uuid primary key default gen_random_uuid(),
  house_id uuid not null references public.houses(id) on delete cascade,
  name text not null,
  owner_name text not null default 'Casa',
  bank_name text not null default '',
  closing_day int check (closing_day is null or closing_day between 1 and 31),
  due_day int check (due_day is null or due_day between 1 and 31),
  limit_amount numeric(14,2),
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  house_id uuid not null references public.houses(id) on delete cascade,
  name text not null,
  target_amount numeric(14,2) not null check (target_amount > 0),
  current_amount numeric(14,2) not null default 0,
  owner_name text not null default 'Casa',
  target_date date,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.goal_movements (
  id uuid primary key default gen_random_uuid(),
  house_id uuid not null references public.houses(id) on delete cascade,
  goal_id uuid not null references public.goals(id) on delete cascade,
  amount numeric(14,2) not null check (amount > 0),
  kind text not null check (kind in ('deposit', 'withdraw')),
  note text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists idx_financial_cards_house on public.financial_cards(house_id);
create index if not exists idx_goals_house on public.goals(house_id);
create index if not exists idx_goal_movements_house on public.goal_movements(house_id);
create index if not exists idx_goal_movements_goal on public.goal_movements(goal_id);
create index if not exists idx_entries_card on public.entries(card_id);
create index if not exists idx_entries_goal on public.entries(goal_id);

alter table public.entries
  drop constraint if exists entries_card_id_fkey,
  add constraint entries_card_id_fkey foreign key (card_id) references public.financial_cards(id) on delete set null;

alter table public.entries
  drop constraint if exists entries_goal_id_fkey,
  add constraint entries_goal_id_fkey foreign key (goal_id) references public.goals(id) on delete set null;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists financial_cards_set_updated_at on public.financial_cards;
create trigger financial_cards_set_updated_at
before update on public.financial_cards
for each row execute function public.set_updated_at();

drop trigger if exists goals_set_updated_at on public.goals;
create trigger goals_set_updated_at
before update on public.goals
for each row execute function public.set_updated_at();

create or replace function public.apply_goal_movement()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.kind = 'withdraw' then
    update public.goals
    set current_amount = greatest(0, current_amount - new.amount),
        updated_at = now()
    where id = new.goal_id;
  else
    update public.goals
    set current_amount = current_amount + new.amount,
        updated_at = now()
    where id = new.goal_id;
  end if;
  return new;
end;
$$;

drop trigger if exists goal_movements_apply on public.goal_movements;
create trigger goal_movements_apply
after insert on public.goal_movements
for each row execute function public.apply_goal_movement();

alter table public.financial_cards enable row level security;
alter table public.goals enable row level security;
alter table public.goal_movements enable row level security;

-- Cards

drop policy if exists "financial_cards_select_member" on public.financial_cards;
create policy "financial_cards_select_member"
on public.financial_cards for select
to authenticated
using (public.is_house_member(house_id));

drop policy if exists "financial_cards_insert_member" on public.financial_cards;
create policy "financial_cards_insert_member"
on public.financial_cards for insert
to authenticated
with check (public.is_house_member(house_id));

drop policy if exists "financial_cards_update_member" on public.financial_cards;
create policy "financial_cards_update_member"
on public.financial_cards for update
to authenticated
using (public.is_house_member(house_id))
with check (public.is_house_member(house_id));

drop policy if exists "financial_cards_delete_admin" on public.financial_cards;
create policy "financial_cards_delete_admin"
on public.financial_cards for delete
to authenticated
using (public.is_house_admin(house_id));

-- Goals

drop policy if exists "goals_select_member" on public.goals;
create policy "goals_select_member"
on public.goals for select
to authenticated
using (public.is_house_member(house_id));

drop policy if exists "goals_insert_member" on public.goals;
create policy "goals_insert_member"
on public.goals for insert
to authenticated
with check (public.is_house_member(house_id));

drop policy if exists "goals_update_member" on public.goals;
create policy "goals_update_member"
on public.goals for update
to authenticated
using (public.is_house_member(house_id))
with check (public.is_house_member(house_id));

drop policy if exists "goals_delete_admin" on public.goals;
create policy "goals_delete_admin"
on public.goals for delete
to authenticated
using (public.is_house_admin(house_id));

-- Goal movements

drop policy if exists "goal_movements_select_member" on public.goal_movements;
create policy "goal_movements_select_member"
on public.goal_movements for select
to authenticated
using (public.is_house_member(house_id));

drop policy if exists "goal_movements_insert_member" on public.goal_movements;
create policy "goal_movements_insert_member"
on public.goal_movements for insert
to authenticated
with check (public.is_house_member(house_id));

-- Seed opcional para casas que ainda não têm cartões/metas
insert into public.financial_cards (house_id, name, owner_name, bank_name, closing_day, due_day, created_by)
select h.id, x.name, x.owner_name, x.bank_name, x.closing_day, x.due_day, auth.uid()
from public.houses h
cross join (values
  ('Cartão principal', 'Casa', '', null::int, null::int)
) as x(name, owner_name, bank_name, closing_day, due_day)
where public.is_house_member(h.id)
  and not exists (select 1 from public.financial_cards c where c.house_id = h.id);

insert into public.goals (house_id, name, target_amount, current_amount, owner_name, created_by)
select h.id, x.name, x.target_amount, x.current_amount, x.owner_name, auth.uid()
from public.houses h
cross join (values
  ('Reserva de emergência', 10000.00::numeric, 0.00::numeric, 'Casa'),
  ('Viagem', 5000.00::numeric, 0.00::numeric, 'Casa')
) as x(name, target_amount, current_amount, owner_name)
where public.is_house_member(h.id)
  and not exists (select 1 from public.goals g where g.house_id = h.id);
