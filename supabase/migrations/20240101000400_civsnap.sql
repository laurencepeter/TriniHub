-- CivSnap issue reporting: tables, storage bucket, and base RLS.
-- (Originally supabase_civsnap_schema.sql.)

create extension if not exists "uuid-ossp";

-- Create a public storage bucket for CivSnap photos
do $$
begin
  if not exists (select 1 from storage.buckets where id = 'civsnap') then
    perform storage.create_bucket('civsnap', public := true);
  end if;
end $$;

-- Table: civsnap_reports
create table if not exists trinihub.civsnap_reports (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references auth.users(id) on delete cascade,
    title text not null,
    description text,
    photo_url text,
    latitude double precision not null,
    longitude double precision not null,
    accuracy_m double precision,
    location_label text,
    status text not null default 'pending' check (status in ('pending', 'under_review', 'in_progress', 'completed', 'open')),
    status_comment text,
    is_anonymous boolean not null default false,
    created_at timestamptz not null default now()
);

create index if not exists civsnap_reports_location_idx on trinihub.civsnap_reports (latitude, longitude);
create index if not exists civsnap_reports_created_idx on trinihub.civsnap_reports (created_at desc);

-- Table: civsnap_votes
create table if not exists trinihub.civsnap_votes (
    id uuid primary key default uuid_generate_v4(),
    report_id uuid not null references trinihub.civsnap_reports(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    created_at timestamptz not null default now(),
    unique (report_id, user_id)
);

create index if not exists civsnap_votes_report_idx on trinihub.civsnap_votes (report_id);

-- Enable row level security
alter table trinihub.civsnap_reports enable row level security;
alter table trinihub.civsnap_votes enable row level security;

-- Policies: allow authenticated users to read reports and votes
drop policy if exists "Authenticated read access" on trinihub.civsnap_reports;
create policy "Authenticated read access" on trinihub.civsnap_reports
  for select using (auth.role() = 'authenticated');

drop policy if exists "Authenticated read access" on trinihub.civsnap_votes;
create policy "Authenticated read access" on trinihub.civsnap_votes
  for select using (auth.role() = 'authenticated');

-- Policies: allow authenticated users to insert their own reports and votes
drop policy if exists "Authenticated insert reports" on trinihub.civsnap_reports;
create policy "Authenticated insert reports" on trinihub.civsnap_reports
  for insert with check (auth.role() = 'authenticated' and user_id = auth.uid());

drop policy if exists "Authenticated insert votes" on trinihub.civsnap_votes;
create policy "Authenticated insert votes" on trinihub.civsnap_votes
  for insert with check (auth.role() = 'authenticated' and user_id = auth.uid());

-- Storage policies for civsnap bucket
drop policy if exists "Authenticated civsnap read" on storage.objects;
create policy "Authenticated civsnap read" on storage.objects
  for select using (bucket_id = 'civsnap' and auth.role() = 'authenticated');

drop policy if exists "Authenticated civsnap insert" on storage.objects;
create policy "Authenticated civsnap insert" on storage.objects
  for insert with check (bucket_id = 'civsnap' and auth.role() = 'authenticated');
