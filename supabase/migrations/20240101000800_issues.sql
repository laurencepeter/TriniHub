-- Community issue reporting with photos, location, severity, and popularity.
-- (Originally supabase_issue_schema.sql.)
--
-- NOTE: the original script used `create type if not exists ...`, which is not
-- valid PostgreSQL for enum types and would abort on a clean run. The enum
-- creation is wrapped in guarded DO blocks below so this migration is safe to
-- apply to a fresh database.

create extension if not exists "uuid-ossp";

-- Enumerations
do $$
begin
  if not exists (select 1 from pg_type where typname = 'issue_severity') then
    create type trinihub.issue_severity as enum ('low', 'medium', 'high', 'critical');
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'issue_status') then
    create type trinihub.issue_status as enum ('open', 'in_progress', 'resolved', 'closed');
  end if;
end $$;

-- Table: issues (canonical issue record)
create table if not exists trinihub.issues (
    id uuid primary key default uuid_generate_v4(),
    title text not null,
    description text,
    category text,
    severity trinihub.issue_severity not null default 'medium',
    status trinihub.issue_status not null default 'open',
    latitude numeric(9, 6) not null check (latitude between -90 and 90),
    longitude numeric(9, 6) not null check (longitude between -180 and 180),
    location_accuracy_m numeric(6, 2),
    landmark text,
    region_name text,
    region_code text,
    municipality text,
    issue_fingerprint text,
    created_by uuid references auth.users(id),
    reported_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Table: issue_reports (each submission with camera + location metadata)
create table if not exists trinihub.issue_reports (
    id uuid primary key default uuid_generate_v4(),
    issue_id uuid not null references trinihub.issues(id) on delete cascade,
    reporter_id uuid references auth.users(id),
    notes text,
    photo_url text,
    photo_mime_type text,
    photo_blurhash text,
    captured_at timestamptz,
    latitude numeric(9, 6) check (latitude between -90 and 90),
    longitude numeric(9, 6) check (longitude between -180 and 180),
    location_accuracy_m numeric(6, 2),
    region_name text,
    region_code text,
    municipality text,
    device_metadata jsonb,
    created_at timestamptz not null default now()
);

-- Table: issue_votes (popularity/confirmation from community)
create table if not exists trinihub.issue_votes (
    id uuid primary key default uuid_generate_v4(),
    issue_id uuid not null references trinihub.issues(id) on delete cascade,
    voter_id uuid references auth.users(id),
    voter_hash text,
    created_at timestamptz not null default now(),
    constraint issue_votes_voter_check check (voter_id is not null or voter_hash is not null)
);

-- Indexes for faster filtering
create index if not exists issues_reported_at_idx on trinihub.issues (reported_at desc);
create index if not exists issues_severity_idx on trinihub.issues (severity);
create index if not exists issues_status_idx on trinihub.issues (status);
create unique index if not exists issues_issue_fingerprint_idx on trinihub.issues (issue_fingerprint)
  where issue_fingerprint is not null;
create index if not exists issue_reports_issue_id_idx on trinihub.issue_reports (issue_id);
create index if not exists issue_votes_issue_id_idx on trinihub.issue_votes (issue_id);

-- Ensure unique votes per user/device
create unique index if not exists issue_votes_unique_voter_id on trinihub.issue_votes (issue_id, voter_id)
  where voter_id is not null;
create unique index if not exists issue_votes_unique_voter_hash on trinihub.issue_votes (issue_id, voter_hash)
  where voter_hash is not null;

-- Popularity view for quick aggregation
create or replace view trinihub.issue_popularity as
select
    issues.id as issue_id,
    issues.title,
    issues.severity,
    issues.status,
    count(distinct issue_reports.id) as report_count,
    count(distinct issue_votes.id) as vote_count,
    (count(distinct issue_reports.id) + count(distinct issue_votes.id))::int as popularity_score
from trinihub.issues
left join trinihub.issue_reports on issue_reports.issue_id = issues.id
left join trinihub.issue_votes on issue_votes.issue_id = issues.id
group by issues.id;

-- Updated_at trigger
create or replace function trinihub.set_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

drop trigger if exists set_issues_updated_at on trinihub.issues;
create trigger set_issues_updated_at
before update on trinihub.issues
for each row
execute function trinihub.set_updated_at();

-- Enable row level security
alter table trinihub.issues enable row level security;
alter table trinihub.issue_reports enable row level security;
alter table trinihub.issue_votes enable row level security;

-- Public read access
drop policy if exists "Public read access" on trinihub.issues;
create policy "Public read access" on trinihub.issues
  for select using (true);

drop policy if exists "Public read access" on trinihub.issue_reports;
create policy "Public read access" on trinihub.issue_reports
  for select using (true);

drop policy if exists "Public read access" on trinihub.issue_votes;
create policy "Public read access" on trinihub.issue_votes
  for select using (true);

-- Public insert access (for community reporting)
drop policy if exists "Public insert" on trinihub.issues;
create policy "Public insert" on trinihub.issues
  for insert with check (
    auth.role() in ('anon', 'authenticated')
    and (created_by is null or created_by = auth.uid())
  );

drop policy if exists "Public insert" on trinihub.issue_reports;
create policy "Public insert" on trinihub.issue_reports
  for insert with check (
    auth.role() in ('anon', 'authenticated')
    and (reporter_id is null or reporter_id = auth.uid())
  );

drop policy if exists "Public insert" on trinihub.issue_votes;
create policy "Public insert" on trinihub.issue_votes
  for insert with check (
    auth.role() in ('anon', 'authenticated')
    and (voter_id is null or voter_id = auth.uid())
  );

-- Authenticated updates for owners
drop policy if exists "Owner update" on trinihub.issues;
create policy "Owner update" on trinihub.issues
  for update using (
    auth.role() = 'authenticated'
    and (
      created_by = auth.uid()
      or (auth.jwt() ->> 'app_role') = 'admin'
    )
  );
