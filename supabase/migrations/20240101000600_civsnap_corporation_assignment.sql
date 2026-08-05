-- Persist corporation assignment on CivSnap reports.
-- (Originally supabase_civsnap_corporation_assignment.sql.
--  Depends on 20240101000000_foundation.sql and 20240101000400_civsnap.sql.)
--
-- Both automatic boundary assignment (BoundaryService point-in-polygon at
-- submit time) and manual reassignment write these columns.

alter table public.civsnap_reports
  add column if not exists corporation_id uuid,
  add column if not exists assigned_at timestamptz,
  add column if not exists assignment_note text;

-- Bind corporation_id to the corporations table when that table exists.
do $$
begin
  if exists (
        select 1 from information_schema.tables
        where table_schema = 'public' and table_name = 'corporations'
     )
     and not exists (
        select 1 from information_schema.table_constraints
        where constraint_name = 'civsnap_reports_corporation_id_fkey'
     ) then
    alter table public.civsnap_reports
      add constraint civsnap_reports_corporation_id_fkey
      foreign key (corporation_id) references public.corporations(id) on delete set null;
  end if;
end $$;

create index if not exists civsnap_reports_corporation_idx
  on public.civsnap_reports (corporation_id);

-- Reassignment is an UPDATE; the existing "admin/corporation can update issues"
-- policy (20240101000500_civsnap_access.sql) already authorizes it.
