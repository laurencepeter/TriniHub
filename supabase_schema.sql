-- SQL schema for tracking file scans in Supabase

-- Enable the required extension for UUID generation
create extension if not exists "uuid-ossp";

-- Table: files
create table if not exists public.files (
    id uuid primary key default uuid_generate_v4(),
    description text
);

-- Table: departments
create table if not exists public.departments (
    id uuid primary key default uuid_generate_v4(),
    name text not null
);

-- Table: file_scans
create table if not exists public.file_scans (
    id uuid primary key default uuid_generate_v4(),
    file_id uuid not null references public.files(id) on delete cascade,
    department_id uuid not null references public.departments(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    event_type text not null check (event_type in ('in', 'out')),
    scan_time timestamptz not null default now()
);

-- Index to quickly query scan history by time
create index if not exists file_scans_scan_time_idx on public.file_scans (scan_time);

-- Enable row level security
alter table public.files enable row level security;
alter table public.departments enable row level security;
alter table public.file_scans enable row level security;

-- Policies: allow authenticated users to read tables
create policy "Authenticated read access" on public.files
  for select using (auth.role() = 'authenticated');

create policy "Authenticated read access" on public.departments
  for select using (auth.role() = 'authenticated');

create policy "Authenticated read access" on public.file_scans
  for select using (auth.role() = 'authenticated');

-- Policies: allow authenticated users to insert scan events
create policy "Authenticated insert" on public.file_scans
  for insert with check (auth.role() = 'authenticated' and user_id = auth.uid());

-- Optional: allow authenticated users to insert files and departments
create policy "Authenticated insert" on public.files
  for insert with check (auth.role() = 'authenticated');

create policy "Authenticated insert" on public.departments
  for insert with check (auth.role() = 'authenticated');

-- Admin view and RPC to list users
create or replace view public.admin_users_view as
select
  u.id as user_id,
  u.email,
  u.created_at,
  p.role,
  p.corporation_id
from auth.users u
left join public.user_profiles p on p.user_id = u.id;

create or replace function public.admin_list_users()
returns table (
  user_id uuid,
  email text,
  created_at timestamptz,
  role text,
  corporation_id uuid
)
language sql
security definer
set search_path = ''
as $$
  select
    u.id,
    u.email,
    u.created_at,
    p.role,
    p.corporation_id
  from auth.users u
  left join public.user_profiles p on p.user_id = u.id
  where exists (
    select 1
    from public.user_profiles ap
    where ap.user_id = auth.uid()
      and (ap.role = 'admin' or ap.app_role = 'admin')
  )
  or (select auth.jwt()) ->> 'app_role' = 'admin'
  order by u.created_at desc;
$$;

revoke all on function public.admin_list_users() from public;
grant execute on function public.admin_list_users() to authenticated;
