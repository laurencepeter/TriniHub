-- Add organization names to user profiles and backfill from corporations.

alter table public.user_profiles
  add column if not exists organization text;

-- Backfill organization names from corporations when a corporation_id exists.
update public.user_profiles p
set organization = r.name
from public.corporations r
where p.corporation_id = r.id
  and (p.organization is null or btrim(p.organization) = '');

-- Optional index to search by organization name.
create index if not exists user_profiles_organization_idx
  on public.user_profiles (organization);
