-- Oria - banco inicial Supabase/PostgreSQL
-- Execute este arquivo no SQL Editor do Supabase.

create extension if not exists pgcrypto;

-- =============================
-- Tipos básicos por CHECK para manter simples no Supabase/PostgREST.
-- =============================

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.houses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  currency text not null default 'BRL',
  owner_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.house_members (
  house_id uuid not null references public.houses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('admin', 'member')),
  status text not null default 'active' check (status in ('active', 'invited', 'blocked')),
  created_at timestamptz not null default now(),
  primary key (house_id, user_id)
);

create table if not exists public.entry_groups (
  id uuid primary key default gen_random_uuid(),
  house_id uuid not null references public.houses(id) on delete cascade,
  name text not null,
  kind text not null check (kind in ('income', 'expense')),
  color text not null default '#1D4ED8',
  sort_order int not null default 0,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (house_id, name)
);

create table if not exists public.entries (
  id uuid primary key default gen_random_uuid(),
  house_id uuid not null references public.houses(id) on delete cascade,
  group_id uuid references public.entry_groups(id) on delete set null,
  title text not null,
  amount numeric(12,2) not null check (amount >= 0),
  type text not null check (type in ('income', 'expense')),
  status text not null default 'pending' check (status in ('pending', 'paid', 'partial', 'ignored')),
  competence_month date not null,
  due_date date,
  responsible text,
  notes text,
  is_recurring boolean not null default false,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  paid_by uuid references auth.users(id) on delete set null,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_house_members_user on public.house_members(user_id);
create index if not exists idx_entry_groups_house on public.entry_groups(house_id);
create index if not exists idx_entries_house_month on public.entries(house_id, competence_month);
create index if not exists idx_entries_group on public.entries(group_id);

-- =============================
-- Updated_at automático
-- =============================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_houses_updated_at on public.houses;
create trigger trg_houses_updated_at
before update on public.houses
for each row execute function public.set_updated_at();

drop trigger if exists trg_entry_groups_updated_at on public.entry_groups;
create trigger trg_entry_groups_updated_at
before update on public.entry_groups
for each row execute function public.set_updated_at();

drop trigger if exists trg_entries_updated_at on public.entries;
create trigger trg_entries_updated_at
before update on public.entries
for each row execute function public.set_updated_at();

-- =============================
-- Perfil automático ao criar auth.users
-- =============================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.email
  )
  on conflict (id) do update
  set email = excluded.email,
      full_name = coalesce(nullif(excluded.full_name, ''), public.profiles.full_name);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- =============================
-- Helpers de segurança
-- =============================

create or replace function public.is_house_member(p_house_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.house_members hm
    where hm.house_id = p_house_id
      and hm.user_id = auth.uid()
      and hm.status = 'active'
  );
$$;

create or replace function public.is_house_admin(p_house_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.house_members hm
    where hm.house_id = p_house_id
      and hm.user_id = auth.uid()
      and hm.status = 'active'
      and hm.role = 'admin'
  );
$$;

-- =============================
-- RPCs usadas pelo Flutter
-- =============================

create or replace function public.get_my_houses()
returns table (
  house_id uuid,
  house_name text,
  role text
)
language sql
stable
security definer
set search_path = public
as $$
  select h.id, h.name, hm.role
  from public.house_members hm
  join public.houses h on h.id = hm.house_id
  where hm.user_id = auth.uid()
    and hm.status = 'active'
  order by h.created_at asc;
$$;

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
    (v_house_id, 'Receitas', 'income', '#15803D', 10, true),
    (v_house_id, 'Despesas fixas da casa', 'expense', '#1D4ED8', 20, true),
    (v_house_id, 'Cartões de crédito', 'expense', '#7C3AED', 30, true),
    (v_house_id, 'Financiamento moto', 'expense', '#EA580C', 40, true),
    (v_house_id, 'Pagar para terceiros', 'expense', '#0F766E', 50, true);

  return v_house_id;
end;
$$;

create or replace function public.seed_oria_spreadsheet_demo(p_house_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  g_receitas uuid;
  g_fixas uuid;
  g_cartoes uuid;
  g_moto uuid;
  g_terceiros uuid;
  v_month date := date '2026-05-01';
begin
  if not public.is_house_admin(p_house_id) then
    raise exception 'Sem permissão para popular esta casa';
  end if;

  select id into g_receitas from public.entry_groups where house_id = p_house_id and name = 'Receitas' limit 1;
  select id into g_fixas from public.entry_groups where house_id = p_house_id and name = 'Despesas fixas da casa' limit 1;
  select id into g_cartoes from public.entry_groups where house_id = p_house_id and name = 'Cartões de crédito' limit 1;
  select id into g_moto from public.entry_groups where house_id = p_house_id and name = 'Financiamento moto' limit 1;
  select id into g_terceiros from public.entry_groups where house_id = p_house_id and name = 'Pagar para terceiros' limit 1;

  if exists (select 1 from public.entries where house_id = p_house_id and competence_month = v_month) then
    return;
  end if;

  insert into public.entries (house_id, group_id, title, amount, type, status, competence_month, due_date, responsible, is_recurring) values
    (p_house_id, g_receitas, 'Salário Jarrye', 2469.00, 'income', 'paid', v_month, date '2026-05-05', 'Jarrye', true),
    (p_house_id, g_receitas, 'Salário Thaissa', 2970.00, 'income', 'paid', v_month, date '2026-05-05', 'Thaissa', true),
    (p_house_id, g_receitas, 'Extra/Abono', 676.00, 'income', 'paid', v_month, date '2026-05-10', 'Casa', false),

    (p_house_id, g_fixas, 'Luz', 167.00, 'expense', 'pending', v_month, date '2026-05-10', 'Casa', true),
    (p_house_id, g_fixas, 'Internet', 160.00, 'expense', 'pending', v_month, date '2026-05-10', 'Casa', true),
    (p_house_id, g_fixas, 'Aluguel Sobrado', 1407.18, 'expense', 'pending', v_month, date '2026-05-10', 'Casa', true),
    (p_house_id, g_fixas, 'Água Sobrado', 68.00, 'expense', 'pending', v_month, date '2026-05-10', 'Casa', true),
    (p_house_id, g_fixas, 'Inglês Jarrye', 140.00, 'expense', 'pending', v_month, date '2026-05-10', 'Jarrye', true),
    (p_house_id, g_fixas, 'Plataformas assinadas', 1023.70, 'expense', 'pending', v_month, date '2026-05-10', 'Casa', true),

    (p_house_id, g_cartoes, 'Inter Jarrye', 965.37, 'expense', 'pending', v_month, date '2026-05-15', 'Jarrye', true),
    (p_house_id, g_cartoes, 'Claro Jarrye', 63.58, 'expense', 'pending', v_month, date '2026-05-15', 'Jarrye', true),
    (p_house_id, g_cartoes, 'Inter Thaissa', 1528.71, 'expense', 'pending', v_month, date '2026-05-15', 'Thaissa', true),
    (p_house_id, g_cartoes, 'Neon', 0.00, 'expense', 'ignored', v_month, date '2026-05-15', 'Casa', true),
    (p_house_id, g_cartoes, 'Nubank', 1801.51, 'expense', 'pending', v_month, date '2026-05-15', 'Casa', true),
    (p_house_id, g_cartoes, 'Empréstimo Inter', 284.00, 'expense', 'pending', v_month, date '2026-05-15', 'Casa', true),

    (p_house_id, g_moto, 'Processo Clio', 400.00, 'expense', 'pending', v_month, date '2026-05-20', 'Casa', true),
    (p_house_id, g_moto, 'Parcela Factor', 400.00, 'expense', 'pending', v_month, date '2026-05-20', 'Jarrye', true),

    (p_house_id, g_terceiros, 'Mercado Pago - 18/05 e 22/05', 276.00, 'expense', 'pending', v_month, date '2026-05-18', 'Casa', false),
    (p_house_id, g_terceiros, 'Advogada', 203.00, 'expense', 'pending', v_month, date '2026-05-20', 'Casa', false),
    (p_house_id, g_terceiros, 'IOFC', 113.00, 'expense', 'pending', v_month, date '2026-05-20', 'Casa', false),
    (p_house_id, g_terceiros, 'Zulma', 100.00, 'expense', 'pending', v_month, date '2026-05-20', 'Casa', false);
end;
$$;


-- =============================
-- Validação de integridade dos lançamentos
-- =============================

create or replace function public.validate_entry_group()
returns trigger
language plpgsql
as $$
declare
  v_group_kind text;
begin
  if new.group_id is null then
    return new;
  end if;

  select kind into v_group_kind
  from public.entry_groups
  where id = new.group_id
    and house_id = new.house_id;

  if v_group_kind is null then
    raise exception 'O grupo informado não pertence a esta casa';
  end if;

  if v_group_kind <> new.type then
    raise exception 'O tipo do lançamento não combina com o tipo do grupo';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validate_entry_group on public.entries;
create trigger trg_validate_entry_group
before insert or update on public.entries
for each row execute function public.validate_entry_group();

-- =============================
-- RLS
-- =============================

alter table public.profiles enable row level security;
alter table public.houses enable row level security;
alter table public.house_members enable row level security;
alter table public.entry_groups enable row level security;
alter table public.entries enable row level security;

-- Profiles

drop policy if exists "profiles_select_own_or_house_members" on public.profiles;
create policy "profiles_select_own_or_house_members"
on public.profiles for select
to authenticated
using (
  id = auth.uid()
  or exists (
    select 1
    from public.house_members hm_self
    join public.house_members hm_other on hm_other.house_id = hm_self.house_id
    where hm_self.user_id = auth.uid()
      and hm_self.status = 'active'
      and hm_other.user_id = profiles.id
      and hm_other.status = 'active'
  )
);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- Houses

drop policy if exists "houses_select_member" on public.houses;
create policy "houses_select_member"
on public.houses for select
to authenticated
using (public.is_house_member(id));

drop policy if exists "houses_insert_owner" on public.houses;
create policy "houses_insert_owner"
on public.houses for insert
to authenticated
with check (owner_id = auth.uid());

drop policy if exists "houses_update_admin" on public.houses;
create policy "houses_update_admin"
on public.houses for update
to authenticated
using (public.is_house_admin(id))
with check (public.is_house_admin(id));

-- House members

drop policy if exists "house_members_select_same_house" on public.house_members;
create policy "house_members_select_same_house"
on public.house_members for select
to authenticated
using (public.is_house_member(house_id));

drop policy if exists "house_members_insert_admin_or_self_owner" on public.house_members;
create policy "house_members_insert_admin_or_self_owner"
on public.house_members for insert
to authenticated
with check (public.is_house_admin(house_id) or user_id = auth.uid());

drop policy if exists "house_members_update_admin" on public.house_members;
create policy "house_members_update_admin"
on public.house_members for update
to authenticated
using (public.is_house_admin(house_id))
with check (public.is_house_admin(house_id));

-- Entry groups

drop policy if exists "entry_groups_select_member" on public.entry_groups;
create policy "entry_groups_select_member"
on public.entry_groups for select
to authenticated
using (public.is_house_member(house_id));

drop policy if exists "entry_groups_insert_admin" on public.entry_groups;
create policy "entry_groups_insert_admin"
on public.entry_groups for insert
to authenticated
with check (public.is_house_admin(house_id));

drop policy if exists "entry_groups_update_admin" on public.entry_groups;
create policy "entry_groups_update_admin"
on public.entry_groups for update
to authenticated
using (public.is_house_admin(house_id))
with check (public.is_house_admin(house_id));

drop policy if exists "entry_groups_delete_admin" on public.entry_groups;
create policy "entry_groups_delete_admin"
on public.entry_groups for delete
to authenticated
using (public.is_house_admin(house_id));

-- Entries

drop policy if exists "entries_select_member" on public.entries;
create policy "entries_select_member"
on public.entries for select
to authenticated
using (public.is_house_member(house_id));

drop policy if exists "entries_insert_member" on public.entries;
create policy "entries_insert_member"
on public.entries for insert
to authenticated
with check (public.is_house_member(house_id));

drop policy if exists "entries_update_member" on public.entries;
create policy "entries_update_member"
on public.entries for update
to authenticated
using (public.is_house_member(house_id))
with check (public.is_house_member(house_id));

drop policy if exists "entries_delete_admin" on public.entries;
create policy "entries_delete_admin"
on public.entries for delete
to authenticated
using (public.is_house_admin(house_id));

-- Permissões RPC

grant usage on schema public to authenticated;
grant execute on function public.get_my_houses() to authenticated;
grant execute on function public.create_house_with_defaults(text) to authenticated;
grant execute on function public.seed_oria_spreadsheet_demo(uuid) to authenticated;
grant execute on function public.is_house_member(uuid) to authenticated;
grant execute on function public.is_house_admin(uuid) to authenticated;
