-- Admin helper function and admin-manage policy for user profiles.
-- (Originally supabase_admin_policies.sql. Defines public.is_admin(), which the
--  dog RLS migration depends on, so this must run before it.)

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select (auth.jwt() ->> 'app_role') = 'admin'
    or exists (
      select 1
      from public.user_profiles p
      where p.user_id = auth.uid()
        and (p.role = 'admin' or p.app_role = 'admin')
    );
$$;

-- User profiles: administrators can manage all profiles.
alter table public.user_profiles enable row level security;

drop policy if exists user_profiles_admin_all on public.user_profiles;
create policy user_profiles_admin_all
on public.user_profiles
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());
