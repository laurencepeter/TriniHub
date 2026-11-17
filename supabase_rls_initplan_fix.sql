-- Migration: fix Supabase `auth_rls_initplan` performance warnings.
--
-- Wraps auth.role() / auth.uid() calls inside the TriniHub RLS policies in a
-- scalar subquery, i.e. `(select auth.role())`, so Postgres evaluates them once
-- per query instead of re-evaluating for every row. This is a pure performance
-- change; the access rules are identical.
--
-- Policy names below match the LIVE database (as reported by the linter), which
-- differ slightly from the names in supabase_schema.sql / supabase_file_custody_schema.sql.
-- Only TriniHub's own tables are touched here.
--
-- Safe to run more than once (drop ... if exists before each create).

begin;

-- public.files -----------------------------------------------------------
drop policy if exists "Authenticated read files" on public.files;
create policy "Authenticated read files" on public.files
  for select using ((select auth.role()) = 'authenticated');

drop policy if exists "Authenticated insert files" on public.files;
create policy "Authenticated insert files" on public.files
  for insert with check ((select auth.role()) = 'authenticated');

drop policy if exists "Authenticated update files" on public.files;
create policy "Authenticated update files" on public.files
  for update using ((select auth.role()) = 'authenticated')
  with check ((select auth.role()) = 'authenticated');

-- public.departments -----------------------------------------------------
drop policy if exists "Authenticated read departments" on public.departments;
create policy "Authenticated read departments" on public.departments
  for select using ((select auth.role()) = 'authenticated');

drop policy if exists "Authenticated insert departments" on public.departments;
create policy "Authenticated insert departments" on public.departments
  for insert with check ((select auth.role()) = 'authenticated');

-- public.file_scans ------------------------------------------------------
drop policy if exists "Authenticated read file_scans" on public.file_scans;
create policy "Authenticated read file_scans" on public.file_scans
  for select using ((select auth.role()) = 'authenticated');

drop policy if exists "Authenticated insert custody" on public.file_scans;
create policy "Authenticated insert custody" on public.file_scans
  for insert with check (
    (select auth.role()) = 'authenticated' and actor_id = (select auth.uid())
  );

commit;
