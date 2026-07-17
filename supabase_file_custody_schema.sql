-- Migration: extend file_scans for QR-based file custody tracking.
--
-- Adds actor vs. custodian separation so a hand-off can record the person
-- TAKING the file (scanned via their 60s badge QR) distinctly from the person
-- who performed the scan. Run this after supabase_schema.sql.

-- 1. Custody columns -------------------------------------------------------
alter table public.file_scans
  add column if not exists actor_id uuid references auth.users(id) on delete set null,
  add column if not exists actor_label text,
  add column if not exists custodian_id uuid references auth.users(id) on delete set null,
  add column if not exists custodian_label text,
  add column if not exists note text;

-- 2. Backfill actor from the legacy user_id -------------------------------
update public.file_scans set actor_id = user_id where actor_id is null;
update public.file_scans set custodian_id = user_id where custodian_id is null;

-- 3. Department is optional for personal hand-offs -------------------------
alter table public.file_scans alter column department_id drop not null;

-- 4. user_id is now derived from actor_id; keep it but allow null ----------
alter table public.file_scans alter column user_id drop not null;

-- 5. Expand the allowed event types (legacy in/out preserved) --------------
alter table public.file_scans drop constraint if exists file_scans_event_type_check;
alter table public.file_scans
  add constraint file_scans_event_type_check
  check (event_type in ('in', 'out', 'received', 'checked_out', 'transferred'));

-- 6. RLS: the scanning user must be the recorded actor --------------------
drop policy if exists "Authenticated insert" on public.file_scans;
create policy "Authenticated insert custody" on public.file_scans
  for insert
  with check (auth.role() = 'authenticated' and actor_id = auth.uid());

-- 7. Allow authenticated users to keep the files registry in sync ---------
--    (upsert on scan so an unseen file id satisfies the foreign key).
drop policy if exists "Authenticated update files" on public.files;
create policy "Authenticated update files" on public.files
  for update using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- 8. Fast per-file custody history ----------------------------------------
create index if not exists file_scans_file_time_idx
  on public.file_scans (file_id, scan_time desc);
