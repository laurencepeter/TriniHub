-- Bootstrap admin access for a specific Supabase user.
-- Replace the email below with the admin's email address.

with target_user as (
  select id
  from auth.users
  where email = 'admin@example.com'
)
insert into public.user_profiles (user_id, role, app_role, created_at, updated_at)
select id, 'admin', 'admin', now(), now()
from target_user
on conflict (user_id) do update
set role = 'admin',
    app_role = 'admin',
    updated_at = now();
