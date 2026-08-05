-- Admin helper function and admin-manage policy for user profiles.
-- (Originally supabase_admin_policies.sql. Defines trinihub.is_admin(), which the
--  dog RLS migration depends on, so this must run before it.)

create or replace function trinihub.is_admin()
returns boolean
language sql
security definer
set search_path = ''
as $$
  select (auth.jwt() ->> 'app_role') = 'admin'
    or exists (
      select 1
      from trinihub.user_profiles p
      where p.user_id = auth.uid()
        and (p.role = 'admin' or p.app_role = 'admin')
    );
$$;

-- User profiles: administrators can manage all profiles.
alter table trinihub.user_profiles enable row level security;

drop policy if exists user_profiles_admin_all on trinihub.user_profiles;
create policy user_profiles_admin_all
on trinihub.user_profiles
for all
to authenticated
using (trinihub.is_admin())
with check (trinihub.is_admin());
