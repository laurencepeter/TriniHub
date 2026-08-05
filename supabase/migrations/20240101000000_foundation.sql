-- Foundational objects that the rest of the schema depends on.
--
-- IMPORTANT: `trinihub.corporations` and `trinihub.user_profiles` are referenced by
-- almost every other migration (foreign keys, RLS policies, the admin view/RPC)
-- and by the Flutter services, but the original standalone scripts never
-- contained a CREATE TABLE for them -- they were provisioned by hand in the
-- Supabase dashboard. Their definitions below are RECONSTRUCTED from how the
-- app and the other scripts use them so that a fresh project can be built
-- purely from these migrations. Review the columns against your live database
-- before running against an existing project.

create extension if not exists "uuid-ossp";

-- ─────────────────────────────────────────────────────────────────────────────
-- Schema + role grants
--
-- All application objects live in the `trinihub` schema rather than `public`.
-- Unlike `public`, a custom schema is NOT automatically exposed to the API or
-- granted to Supabase's roles, so we do that explicitly here. Row-level
-- security still governs actual row access; these grants only let PostgREST
-- (as anon / authenticated) and the service role reach the schema at all.
--
-- You ALSO have to expose the schema in the dashboard: Project Settings → API →
-- Exposed schemas → add `trinihub`. (Locally, supabase/config.toml does this.)
-- ─────────────────────────────────────────────────────────────────────────────
create schema if not exists trinihub;

grant usage on schema trinihub to anon, authenticated, service_role;

-- Cover objects created later in this migration and every migration after it.
alter default privileges in schema trinihub
    grant all on tables to anon, authenticated, service_role;
alter default privileges in schema trinihub
    grant all on functions to anon, authenticated, service_role;
alter default privileges in schema trinihub
    grant all on sequences to anon, authenticated, service_role;

-- ─────────────────────────────────────────────────────────────────────────────
-- Corporations (municipal/regional corporations used across the app)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists trinihub.corporations (
    id uuid primary key default uuid_generate_v4(),
    name text not null,
    created_at timestamptz not null default now()
);

alter table trinihub.corporations enable row level security;

drop policy if exists corporations_read_all on trinihub.corporations;
create policy corporations_read_all on trinihub.corporations
    for select using (auth.role() = 'authenticated');

-- ─────────────────────────────────────────────────────────────────────────────
-- User profiles (role + corporation binding for each auth user)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists trinihub.user_profiles (
    user_id uuid primary key references auth.users(id) on delete cascade,
    role text,
    app_role text,
    corporation_id uuid references trinihub.corporations(id) on delete set null,
    display_name text,
    region_code text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists user_profiles_corporation_idx
    on trinihub.user_profiles (corporation_id);

alter table trinihub.user_profiles enable row level security;

-- A user can always read and manage their own profile row.
drop policy if exists user_profiles_read_own on trinihub.user_profiles;
create policy user_profiles_read_own on trinihub.user_profiles
    for select using (user_id = auth.uid());

drop policy if exists user_profiles_insert_own on trinihub.user_profiles;
create policy user_profiles_insert_own on trinihub.user_profiles
    for insert with check (user_id = auth.uid());

drop policy if exists user_profiles_update_own on trinihub.user_profiles;
create policy user_profiles_update_own on trinihub.user_profiles
    for update using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Convenience view the app reads for the current user's profile
-- (lib/widgets/role_gate.dart queries `my_profile`).
create or replace view trinihub.my_profile as
    select * from trinihub.user_profiles where user_id = auth.uid();
