-- Oria v9: limpeza profissional, nomenclatura simples e preparação para recursos futuros

-- Status cancelado é usado pelo app, então a constraint precisa permitir.
alter table public.entries
  drop constraint if exists entries_status_check;

alter table public.entries
  add constraint entries_status_check
  check (status in ('pending', 'paid', 'partial', 'ignored', 'canceled'));

-- Nomes padrão mais simples para novas casas.
create or replace function public.create_house_with_defaults(p_house_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_house_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;

  insert into public.houses (name, owner_id)
  values (coalesce(nullif(trim(p_house_name), ''), 'Minha casa'), auth.uid())
  returning id into v_house_id;

  insert into public.house_members (house_id, user_id, role, status)
  values (v_house_id, auth.uid(), 'admin', 'active');

  insert into public.entry_groups (house_id, name, kind, color, sort_order, is_default) values
    (v_house_id, 'Entrada', 'income', '#15803D', 10, true),
    (v_house_id, 'Casa', 'expense', '#1D4ED8', 20, true),
    (v_house_id, 'Cartão de crédito', 'expense', '#7C3AED', 30, true),
    (v_house_id, 'Moto/Carro', 'expense', '#EA580C', 40, true),
    (v_house_id, 'Porquinho', 'expense', '#0F766E', 50, true),
    (v_house_id, 'Outros', 'expense', '#64748B', 60, true);

  return v_house_id;
end;
$$;

-- Ajusta nomes antigos sem apagar dados.
update public.entry_groups
set name = 'Entrada'
where name = 'Receitas';

update public.entry_groups
set name = 'Casa'
where name = 'Despesas fixas da casa';

update public.entry_groups
set name = 'Cartão de crédito'
where name = 'Cartões de crédito';

update public.entry_groups
set name = 'Moto/Carro'
where name = 'Financiamento moto';

update public.entry_groups
set name = 'Outros'
where name = 'Pagar para terceiros';

-- Tabelas preparatórias para importação e roadmap interno.
create table if not exists public.import_batches (
  id uuid primary key default gen_random_uuid(),
  house_id uuid not null references public.houses(id) on delete cascade,
  file_name text not null,
  source text not null default 'manual',
  status text not null default 'created' check (status in ('created', 'processing', 'done', 'failed')),
  total_rows int not null default 0,
  imported_rows int not null default 0,
  error_message text,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.roadmap_items (
  id uuid primary key default gen_random_uuid(),
  house_id uuid not null references public.houses(id) on delete cascade,
  title text not null,
  description text,
  status text not null default 'planned' check (status in ('idea', 'planned', 'doing', 'done', 'canceled')),
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_import_batches_house on public.import_batches(house_id);
create index if not exists idx_roadmap_items_house on public.roadmap_items(house_id);

drop trigger if exists roadmap_items_set_updated_at on public.roadmap_items;
create trigger roadmap_items_set_updated_at
before update on public.roadmap_items
for each row execute function public.set_updated_at();

alter table public.import_batches enable row level security;
alter table public.roadmap_items enable row level security;

drop policy if exists "import_batches_select_member" on public.import_batches;
create policy "import_batches_select_member"
on public.import_batches for select
to authenticated
using (public.is_house_member(house_id));

drop policy if exists "import_batches_insert_member" on public.import_batches;
create policy "import_batches_insert_member"
on public.import_batches for insert
to authenticated
with check (public.is_house_member(house_id));

drop policy if exists "roadmap_items_select_member" on public.roadmap_items;
create policy "roadmap_items_select_member"
on public.roadmap_items for select
to authenticated
using (public.is_house_member(house_id));

drop policy if exists "roadmap_items_insert_member" on public.roadmap_items;
create policy "roadmap_items_insert_member"
on public.roadmap_items for insert
to authenticated
with check (public.is_house_member(house_id));

drop policy if exists "roadmap_items_update_member" on public.roadmap_items;
create policy "roadmap_items_update_member"
on public.roadmap_items for update
to authenticated
using (public.is_house_member(house_id))
with check (public.is_house_member(house_id));
