-- RLS policies to allow authenticated users to insert dog registration data.
-- Apply after running the schema migration that creates the dog registry tables.

begin;

-- Owners: allow authenticated users to insert their own owner profile
drop policy if exists owners_insert_own on public.owners;
create policy owners_insert_own
on public.owners
for insert
to authenticated
with check (auth_user_id = auth.uid());

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

commit;
