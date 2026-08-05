-- Foundational objects that the rest of the schema depends on.
--
-- IMPORTANT: `public.corporations` and `public.user_profiles` are referenced by
-- almost every other migration (foreign keys, RLS policies, the admin view/RPC)
-- and by the Flutter services, but the original standalone scripts never
-- contained a CREATE TABLE for them -- they were provisioned by hand in the
-- Supabase dashboard. Their definitions below are RECONSTRUCTED from how the
-- app and the other scripts use them so that a fresh project can be built
-- purely from these migrations. Review the columns against your live database
-- before running against an existing project.

create extension if not exists "uuid-ossp";

-- ─────────────────────────────────────────────────────────────────────────────
-- Corporations (municipal/regional corporations used across the app)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.corporations (
    id uuid primary key default uuid_generate_v4(),
    name text not null,
    created_at timestamptz not null default now()
);

alter table public.corporations enable row level security;

drop policy if exists corporations_read_all on public.corporations;
create policy corporations_read_all on public.corporations
    for select using (auth.role() = 'authenticated');

-- ─────────────────────────────────────────────────────────────────────────────
-- User profiles (role + corporation binding for each auth user)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.user_profiles (
    user_id uuid primary key references auth.users(id) on delete cascade,
    role text,
    app_role text,
    corporation_id uuid references public.corporations(id) on delete set null,
    display_name text,
    region_code text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists user_profiles_corporation_idx
    on public.user_profiles (corporation_id);

alter table public.user_profiles enable row level security;

-- A user can always read and manage their own profile row.
drop policy if exists user_profiles_read_own on public.user_profiles;
create policy user_profiles_read_own on public.user_profiles
    for select using (user_id = auth.uid());

drop policy if exists user_profiles_insert_own on public.user_profiles;
create policy user_profiles_insert_own on public.user_profiles
    for insert with check (user_id = auth.uid());

drop policy if exists user_profiles_update_own on public.user_profiles;
create policy user_profiles_update_own on public.user_profiles
    for update using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Convenience view the app reads for the current user's profile
-- (lib/widgets/role_gate.dart queries `my_profile`).
create or replace view public.my_profile as
    select * from public.user_profiles where user_id = auth.uid();
