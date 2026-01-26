-- SQL schema for CivSnap role-based access control

create extension if not exists "uuid-ossp";

create table if not exists public.user_roles (
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

create or replace function public.set_user_roles_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists user_roles_updated_at on public.user_roles;
create trigger user_roles_updated_at
before update on public.user_roles
for each row
execute procedure public.set_user_roles_updated_at();

alter table public.user_roles enable row level security;

create policy "Users can read their own role" on public.user_roles
  for select using (user_id = auth.uid());

create policy "Admins can manage roles" on public.user_roles
  for all using ((auth.jwt() ->> 'app_role') = 'admin')
  with check ((auth.jwt() ->> 'app_role') = 'admin');

-- Allow administrators and corporation staff to update issue statuses
create policy "Corp/admin update report status" on public.civsnap_reports
  for update using ((auth.jwt() ->> 'app_role') in ('admin', 'corporation'))
  with check ((auth.jwt() ->> 'app_role') in ('admin', 'corporation'));
