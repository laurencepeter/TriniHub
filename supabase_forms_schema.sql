-- SQL schema for dynamic forms and submissions

create extension if not exists "uuid-ossp";

create table if not exists public.form_templates (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  description text,
  scope text not null check (scope in ('public', 'internal')),
  status text not null check (status in ('draft', 'published', 'archived')),
  pdf_output_bucket text,
  region_id uuid references public.corporations(id),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.form_fields (
  id uuid primary key default uuid_generate_v4(),
  form_id uuid not null references public.form_templates(id) on delete cascade,
  label text not null,
  field_type text not null check (
    field_type in ('short_text', 'long_text', 'number', 'date', 'dropdown', 'checkbox', 'photo', 'location')
  ),
  is_required boolean not null default false,
  options jsonb,
  position int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.form_submissions (
  id uuid primary key default uuid_generate_v4(),
  form_id uuid not null references public.form_templates(id) on delete cascade,
  submitter_id uuid references auth.users(id),
  region_id uuid references public.corporations(id),
  status text not null default 'submitted' check (
    status in ('submitted', 'in_review', 'needs_info', 'approved', 'rejected', 'completed')
  ),
  summary text,
  responses jsonb not null default '{}'::jsonb,
  latitude double precision,
  longitude double precision,
  location_label text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.form_submission_media (
  id uuid primary key default uuid_generate_v4(),
  submission_id uuid not null references public.form_submissions(id) on delete cascade,
  file_url text not null,
  file_type text,
  created_at timestamptz not null default now()
);

create index if not exists form_templates_scope_idx on public.form_templates (scope);
create index if not exists form_templates_status_idx on public.form_templates (status);
create index if not exists form_fields_form_idx on public.form_fields (form_id);
create index if not exists form_submissions_form_idx on public.form_submissions (form_id);
create index if not exists form_submissions_region_idx on public.form_submissions (region_id);
create index if not exists form_submissions_status_idx on public.form_submissions (status);

create or replace function public.set_forms_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create or replace function public.current_app_role()
returns text
language sql
security definer
set search_path = ''
as $$
  select coalesce(
    (auth.jwt() ->> 'app_role'),
    (select role from public.user_profiles where user_id = auth.uid()),
    'public_user'
  );
$$;

create or replace function public.current_corporation_id()
returns uuid
language sql
security definer
set search_path = ''
as $$
  select corporation_id from public.user_profiles where user_id = auth.uid();
$$;

drop trigger if exists form_templates_updated_at on public.form_templates;
create trigger form_templates_updated_at
before update on public.form_templates
for each row
execute procedure public.set_forms_updated_at();

drop trigger if exists form_submissions_updated_at on public.form_submissions;
create trigger form_submissions_updated_at
before update on public.form_submissions
for each row
execute procedure public.set_forms_updated_at();

alter table public.form_templates enable row level security;
alter table public.form_fields enable row level security;
alter table public.form_submissions enable row level security;
alter table public.form_submission_media enable row level security;

create policy "Admin manage templates" on public.form_templates
  for all using (public.current_app_role() = 'admin')
  with check (public.current_app_role() = 'admin');

create policy "Read published templates" on public.form_templates
  for select using (
    public.current_app_role() = 'admin'
    or (
      status = 'published'
      and (
        scope = 'public'
        or (scope = 'internal' and public.current_app_role() in ('admin', 'corporation'))
      )
    )
  );

create policy "Read form fields" on public.form_fields
  for select using (
    exists (
      select 1
      from public.form_templates t
      where t.id = form_id
        and (
          public.current_app_role() = 'admin'
          or (
            t.status = 'published'
            and (
              t.scope = 'public'
              or (t.scope = 'internal' and public.current_app_role() in ('admin', 'corporation'))
            )
          )
        )
    )
  );

create policy "Admin manage fields" on public.form_fields
  for all using (public.current_app_role() = 'admin')
  with check (public.current_app_role() = 'admin');

create policy "Read submissions" on public.form_submissions
  for select using (
    public.current_app_role() = 'admin'
    or (public.current_app_role() = 'corporation' and region_id = public.current_corporation_id())
    or submitter_id = auth.uid()
  );

create policy "Insert submissions" on public.form_submissions
  for insert with check (
    submitter_id = auth.uid()
    and exists (
      select 1
      from public.form_templates t
      where t.id = form_id
        and t.status = 'published'
        and (
          t.scope = 'public'
          or (t.scope = 'internal' and public.current_app_role() in ('admin', 'corporation'))
        )
    )
    and (public.current_app_role() <> 'corporation' or region_id = public.current_corporation_id())
  );

create policy "Update submissions" on public.form_submissions
  for update using (
    public.current_app_role() = 'admin'
    or (public.current_app_role() = 'corporation' and region_id = public.current_corporation_id())
    or submitter_id = auth.uid()
  )
  with check (
    public.current_app_role() = 'admin'
    or (public.current_app_role() = 'corporation' and region_id = public.current_corporation_id())
    or submitter_id = auth.uid()
  );

create policy "Read submission media" on public.form_submission_media
  for select using (
    exists (
      select 1
      from public.form_submissions s
      where s.id = submission_id
        and (
          public.current_app_role() = 'admin'
          or (public.current_app_role() = 'corporation' and s.region_id = public.current_corporation_id())
          or s.submitter_id = auth.uid()
        )
    )
  );

create policy "Insert submission media" on public.form_submission_media
  for insert with check (
    exists (
      select 1
      from public.form_submissions s
      where s.id = submission_id
        and (
          public.current_app_role() = 'admin'
          or (public.current_app_role() = 'corporation' and s.region_id = public.current_corporation_id())
          or s.submitter_id = auth.uid()
        )
    )
  );

insert into storage.buckets (id, name, public)
values ('form-uploads', 'form-uploads', true)
on conflict (id) do nothing;

create policy "Form uploads read" on storage.objects
  for select using (bucket_id = 'form-uploads');

create policy "Form uploads insert" on storage.objects
  for insert with check (bucket_id = 'form-uploads' and auth.role() = 'authenticated');

create policy "Form uploads update" on storage.objects
  for update using (bucket_id = 'form-uploads' and auth.role() = 'authenticated')
  with check (bucket_id = 'form-uploads' and auth.role() = 'authenticated');
