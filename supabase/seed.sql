-- Seed data / one-off bootstrap.
--
-- This runs automatically on `supabase db reset` (local dev). For a hosted
-- project, run the block below manually in the SQL editor AFTER you have
-- created the admin auth user, and replace the email address.
--
-- Bootstrap admin access for a specific Supabase user.
-- The CTE returns no rows if the email does not exist, so this is a safe no-op
-- until the matching user has signed up.

with target_user as (
  select id
  from auth.users
  where email = 'admin@example.com'   -- <-- replace with your admin's email
)
insert into trinihub.user_profiles (user_id, role, app_role)
select id, 'admin', 'admin'
from target_user
on conflict (user_id) do update
set role = 'admin',
    app_role = 'admin';
