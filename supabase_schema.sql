-- SQL schema for tracking file scans and related data in Supabase

-- Enable the required extension for UUID generation
create extension if not exists "uuid-ossp";

-- Table: departments
create table if not exists public.departments (
    id uuid primary key default uuid_generate_v4(),
    name text not null
);

-- Table: files
create table if not exists public.files (
    id uuid primary key default uuid_generate_v4(),
    description text,
    last_activity text,
    last_activity_date timestamptz,
    last_department_id uuid references public.departments(id)
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

-- Trigger to keep file last activity details updated
create or replace function public.update_file_last_activity()
returns trigger as $$
begin
  update public.files
    set last_activity = new.event_type,
        last_activity_date = new.scan_time,
        last_department_id = new.department_id
  where id = new.file_id;
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_update_file_last_activity
after insert on public.file_scans
for each row execute procedure public.update_file_last_activity();

-- Index to quickly query scan history by time
create index if not exists file_scans_scan_time_idx on public.file_scans (scan_time);

-- Table: pay_slips
create table if not exists public.pay_slips (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references auth.users(id) on delete cascade,
    period_start date not null,
    period_end date not null,
    file_url text not null,
    created_at timestamptz not null default now()
);

-- Table: projects
create table if not exists public.projects (
    id uuid primary key default uuid_generate_v4(),
    name text not null,
    description text,
    status text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz
);

-- Table: project_updates
create table if not exists public.project_updates (
    id uuid primary key default uuid_generate_v4(),
    project_id uuid not null references public.projects(id) on delete cascade,
    user_id uuid references auth.users(id),
    status text not null,
    update_text text,
    update_time timestamptz not null default now()
);

-- Table: corporations
create table if not exists public.corporations (
    id uuid primary key default uuid_generate_v4(),
    name text not null unique
);

-- Table: external_reports
create table if not exists public.external_reports (
    id uuid primary key default uuid_generate_v4(),
    reporter_id uuid references auth.users(id),
    corporation_id uuid references public.corporations(id),
    description text,
    lat numeric,
    lon numeric,
    status text default 'new',
    reported_at timestamptz default now()
);

-- Table: external_report_images
create table if not exists public.external_report_images (
    id uuid primary key default uuid_generate_v4(),
    report_id uuid not null references public.external_reports(id) on delete cascade,
    image_url text not null
);

-- Enable row level security
alter table public.files enable row level security;
alter table public.departments enable row level security;
alter table public.file_scans enable row level security;
alter table public.pay_slips enable row level security;
alter table public.projects enable row level security;
alter table public.project_updates enable row level security;
alter table public.corporations enable row level security;
alter table public.external_reports enable row level security;
alter table public.external_report_images enable row level security;

-- Policies: allow authenticated users to read common tables
create policy "Authenticated read access" on public.files
  for select using (auth.role() = 'authenticated');
create policy "Authenticated read access" on public.departments
  for select using (auth.role() = 'authenticated');
create policy "Authenticated read access" on public.file_scans
  for select using (auth.role() = 'authenticated');
create policy "Authenticated read access" on public.pay_slips
  for select using (auth.role() = 'authenticated' and auth.uid() = user_id);
create policy "Authenticated read access" on public.projects
  for select using (auth.role() = 'authenticated');
create policy "Authenticated read access" on public.project_updates
  for select using (auth.role() = 'authenticated');
create policy "Authenticated read access" on public.corporations
  for select using (auth.role() = 'authenticated');
create policy "Authenticated read access" on public.external_reports
  for select using (auth.role() = 'authenticated');
create policy "Authenticated read access" on public.external_report_images
  for select using (auth.role() = 'authenticated');

-- Policies: allow authenticated users to insert relevant data
create policy "Authenticated insert" on public.file_scans
  for insert with check (auth.role() = 'authenticated' and user_id = auth.uid());
create policy "Authenticated insert" on public.files
  for insert with check (auth.role() = 'authenticated');
create policy "Authenticated insert" on public.departments
  for insert with check (auth.role() = 'authenticated');
create policy "Authenticated insert" on public.pay_slips
  for insert with check (auth.role() = 'authenticated' and auth.uid() = user_id);
create policy "Authenticated insert" on public.projects
  for insert with check (auth.role() = 'authenticated');
create policy "Authenticated insert" on public.project_updates
  for insert with check (auth.role() = 'authenticated');
create policy "Authenticated insert" on public.corporations
  for insert with check (auth.role() = 'authenticated');
create policy "Authenticated insert" on public.external_reports
  for insert with check (auth.role() = 'authenticated');
create policy "Authenticated insert" on public.external_report_images
  for insert with check (auth.role() = 'authenticated');
