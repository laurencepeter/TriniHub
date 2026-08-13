-- Bug reporting for the Internal and External service catalogs.
--
-- Backs the "Report a Bug" tiles on both the Internal Services and External
-- Services screens. Until this migration the bug form was a UI-only mock that
-- flipped a local boolean and discarded everything the user typed; it now
-- persists to public.bug_reports so support/engineering has a durable record,
-- and every submission is mirrored into public.audit_logs by the app.
--
-- Depends on:
--   * 20240101000000_foundation.sql   (user_profiles, auth.users)
--   * 20240101000800_issues.sql       (public.set_updated_at trigger fn)
--   * 20240101001100_admin_policies.sql (public.is_admin())

create extension if not exists "uuid-ossp";

-- ──────────────────────────────────────────────────────────────────────────────
-- Enumerations
-- ──────────────────────────────────────────────────────────────────────────────
do $$
begin
  if not exists (select 1 from pg_type where typname = 'bug_report_severity') then
    create type public.bug_report_severity as enum ('low', 'medium', 'high', 'critical');
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'bug_report_status') then
    create type public.bug_report_status as enum ('open', 'triaged', 'in_progress', 'resolved', 'closed');
  end if;
end $$;

-- ──────────────────────────────────────────────────────────────────────────────
-- Bug reports table
-- ──────────────────────────────────────────────────────────────────────────────
create table if not exists public.bug_reports (
    id uuid primary key default uuid_generate_v4(),
    -- Which catalog the report came from: 'internal' or 'external'.
    scope text not null check (scope in ('internal', 'external')),
    title text not null check (char_length(trim(title)) > 0),
    -- Free text: steps to reproduce plus any additional notes.
    description text,
    -- "Module" (internal) / "category" (external) picker value.
    module text,
    severity public.bug_report_severity not null default 'medium',
    status public.bug_report_status not null default 'open',
    -- Reporter identity is captured server-side from the JWT by the app; kept
    -- nullable + "on delete set null" so a report survives account deletion.
    reporter_id uuid references auth.users(id) on delete set null,
    reporter_email text,
    reporter_role text,
    -- Optional follow-up address the reporter typed in (may differ from login).
    contact_email text,
    -- Non-PII diagnostic context: platform, app version, locale, etc.
    app_version text,
    platform text,
    device_metadata jsonb,
    -- Free-form triage notes maintained by admins.
    resolution_notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists bug_reports_created_idx on public.bug_reports (created_at desc);
create index if not exists bug_reports_scope_idx on public.bug_reports (scope);
create index if not exists bug_reports_status_idx on public.bug_reports (status);
create index if not exists bug_reports_severity_idx on public.bug_reports (severity);
create index if not exists bug_reports_reporter_idx on public.bug_reports (reporter_id);

-- Keep updated_at fresh on triage edits (function defined in the issues migration).
drop trigger if exists set_bug_reports_updated_at on public.bug_reports;
create trigger set_bug_reports_updated_at
before update on public.bug_reports
for each row
execute function public.set_updated_at();

-- ──────────────────────────────────────────────────────────────────────────────
-- Row level security
-- ──────────────────────────────────────────────────────────────────────────────
alter table public.bug_reports enable row level security;

-- Reporters may only file a report as themselves (or anonymously with a null
-- reporter_id). This mirrors the "Public insert" pattern used by issues.
drop policy if exists bug_reports_insert_self on public.bug_reports;
create policy bug_reports_insert_self on public.bug_reports
    for insert with check (
        auth.role() = 'authenticated'
        and (reporter_id is null or reporter_id = auth.uid())
    );

-- A reporter can read the reports they filed; admins can read every report.
drop policy if exists bug_reports_read_own on public.bug_reports;
create policy bug_reports_read_own on public.bug_reports
    for select using (
        reporter_id = auth.uid()
        or public.is_admin()
    );

-- Only admins triage (change status / add resolution notes).
drop policy if exists bug_reports_admin_update on public.bug_reports;
create policy bug_reports_admin_update on public.bug_reports
    for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists bug_reports_admin_delete on public.bug_reports;
create policy bug_reports_admin_delete on public.bug_reports
    for delete using (public.is_admin());
