-- RLS policies for the dog registration tables.
-- (Originally supabase_dog_rls_policies.sql. Depends on 20240101000300_dog_registry.sql
--  for the tables and 20240101001100_admin_policies.sql for public.is_admin().)

begin;

-- Enable RLS on dog registration tables.
alter table public.regions enable row level security;
alter table public.breeds enable row level security;
alter table public.owners enable row level security;
alter table public.dogs enable row level security;
alter table public.dog_ownerships enable row level security;

-- Regions/Breeds: allow authenticated users to read lookup data.
drop policy if exists regions_select_all on public.regions;
create policy regions_select_all
on public.regions
for select
to authenticated
using (auth.role() = 'authenticated');

drop policy if exists breeds_select_all on public.breeds;
create policy breeds_select_all
on public.breeds
for select
to authenticated
using (auth.role() = 'authenticated');

-- Owners: allow authenticated users to insert their own owner profile
drop policy if exists owners_insert_own on public.owners;
create policy owners_insert_own
on public.owners
for insert
to authenticated
with check (auth_user_id = auth.uid());

-- Owners: allow authenticated users to read their own owner profile
drop policy if exists owners_select_own on public.owners;
create policy owners_select_own
on public.owners
for select
to authenticated
using (auth_user_id = auth.uid());

-- Dogs: allow authenticated users to insert dogs tied to their owner record
drop policy if exists dogs_insert_owner on public.dogs;
create policy dogs_insert_owner
on public.dogs
for insert
to authenticated
with check (
  exists (
    select 1
    from public.owners o
    where o.id = current_owner_id
      and o.auth_user_id = auth.uid()
  )
);

-- Dogs: allow authenticated users to read their own dogs
drop policy if exists dogs_select_owner on public.dogs;
create policy dogs_select_owner
on public.dogs
for select
to authenticated
using (
  exists (
    select 1
    from public.owners o
    where o.id = current_owner_id
      and o.auth_user_id = auth.uid()
  )
);

-- Ownerships: allow authenticated users to insert ownership history for their owner record
drop policy if exists dog_ownerships_insert_owner on public.dog_ownerships;
create policy dog_ownerships_insert_owner
on public.dog_ownerships
for insert
to authenticated
with check (
  exists (
    select 1
    from public.owners o
    where o.id = owner_id
      and o.auth_user_id = auth.uid()
  )
);

-- Ownerships: allow authenticated users to read their own ownership history
drop policy if exists dog_ownerships_select_owner on public.dog_ownerships;
create policy dog_ownerships_select_owner
on public.dog_ownerships
for select
to authenticated
using (
  exists (
    select 1
    from public.owners o
    where o.id = owner_id
      and o.auth_user_id = auth.uid()
  )
);

-- Admin access: allow administrators to manage all dog registry data.
drop policy if exists owners_admin_all on public.owners;
create policy owners_admin_all
on public.owners
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists dogs_admin_all on public.dogs;
create policy dogs_admin_all
on public.dogs
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists dog_ownerships_admin_all on public.dog_ownerships;
create policy dog_ownerships_admin_all
on public.dog_ownerships
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

commit;
