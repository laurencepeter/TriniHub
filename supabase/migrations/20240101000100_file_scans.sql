-- File scan tracking core tables, plus the admin users view and RPC.
-- (Originally supabase_schema.sql.)

create extension if not exists "uuid-ossp";

-- Table: files
create table if not exists trinihub.files (
    id uuid primary key default uuid_generate_v4(),
    description text
);

-- Table: departments
create table if not exists trinihub.departments (
    id uuid primary key default uuid_generate_v4(),
    name text not null
);

-- Table: file_scans
create table if not exists trinihub.file_scans (
    id uuid primary key default uuid_generate_v4(),
    file_id uuid not null references trinihub.files(id) on delete cascade,
    department_id uuid not null references trinihub.departments(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    event_type text not null check (event_type in ('in', 'out')),
    scan_time timestamptz not null default now()
);

-- Index to quickly query scan history by time
create index if not exists file_scans_scan_time_idx on trinihub.file_scans (scan_time);

-- Enable row level security
alter table trinihub.files enable row level security;
alter table trinihub.departments enable row level security;
alter table trinihub.file_scans enable row level security;

-- Policies: allow authenticated users to read tables
drop policy if exists "Authenticated read access" on trinihub.files;
create policy "Authenticated read access" on trinihub.files
  for select using (auth.role() = 'authenticated');

drop policy if exists "Authenticated read access" on trinihub.departments;
create policy "Authenticated read access" on trinihub.departments
  for select using (auth.role() = 'authenticated');

drop policy if exists "Authenticated read access" on trinihub.file_scans;
create policy "Authenticated read access" on trinihub.file_scans
  for select using (auth.role() = 'authenticated');

-- Policies: allow authenticated users to insert scan events
drop policy if exists "Authenticated insert" on trinihub.file_scans;
create policy "Authenticated insert" on trinihub.file_scans
  for insert with check (auth.role() = 'authenticated' and user_id = auth.uid());

-- Optional: allow authenticated users to insert files and departments
drop policy if exists "Authenticated insert" on trinihub.files;
create policy "Authenticated insert" on trinihub.files
  for insert with check (auth.role() = 'authenticated');

drop policy if exists "Authenticated insert" on trinihub.departments;
create policy "Authenticated insert" on trinihub.departments
  for insert with check (auth.role() = 'authenticated');

-- Admin view and RPC to list users
create or replace view trinihub.admin_users_view as
select
  u.id as user_id,
  u.email,
  u.created_at,
  p.role,
  p.corporation_id
from auth.users u
left join trinihub.user_profiles p on p.user_id = u.id;

create or replace function trinihub.admin_list_users()
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
  left join trinihub.user_profiles p on p.user_id = u.id
  where exists (
    select 1
    from trinihub.user_profiles ap
    where ap.user_id = auth.uid()
      and (ap.role = 'admin' or ap.app_role = 'admin')
  )
  or (select auth.jwt()) ->> 'app_role' = 'admin'
  order by u.created_at desc;
$$;

revoke all on function trinihub.admin_list_users() from public;
grant execute on function trinihub.admin_list_users() to authenticated;
