-- CivSnap role-based access control: user_roles table and status-update policy.
-- (Originally supabase_civsnap_access_schema.sql. Depends on 20240101000400_civsnap.sql.)

create extension if not exists "uuid-ossp";

create table if not exists trinihub.user_roles (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references auth.users(id) on delete cascade,
    role text not null check (role in ('admin', 'corporation', 'public')),
    organization text,
    display_name text,
    email text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (user_id)
);

create or replace function trinihub.set_user_roles_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists user_roles_updated_at on trinihub.user_roles;
create trigger user_roles_updated_at
before update on trinihub.user_roles
for each row
execute procedure trinihub.set_user_roles_updated_at();

alter table trinihub.user_roles enable row level security;

drop policy if exists "Users can read their own role" on trinihub.user_roles;
create policy "Users can read their own role" on trinihub.user_roles
  for select using (user_id = auth.uid());

drop policy if exists "Admins can manage roles" on trinihub.user_roles;
create policy "Admins can manage roles" on trinihub.user_roles
  for all using ((auth.jwt() ->> 'app_role') = 'admin')
  with check ((auth.jwt() ->> 'app_role') = 'admin');

-- Allow administrators and corporation staff to update issue statuses
drop policy if exists "Corp/admin update report status" on trinihub.civsnap_reports;
create policy "Corp/admin update report status" on trinihub.civsnap_reports
  for update using ((auth.jwt() ->> 'app_role') in ('admin', 'corporation'))
  with check ((auth.jwt() ->> 'app_role') in ('admin', 'corporation'));
