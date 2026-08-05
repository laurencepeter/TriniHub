-- Audit logging, in-app notifications, and CivSnap municipality assignment.
-- (Originally supabase_audit_notifications_schema.sql. Depends on
--  foundation, civsnap, and civsnap_corporation_assignment migrations.)

create extension if not exists "uuid-ossp";

-- ──────────────────────────────────────────────────────────────────────────────
-- Audit log table
-- ──────────────────────────────────────────────────────────────────────────────
create table if not exists trinihub.audit_logs (
    id uuid primary key default uuid_generate_v4(),
    actor_id uuid references auth.users(id) on delete set null,
    actor_email text,
    actor_role text,
    action text not null,
    entity_type text,
    entity_id text,
    summary text,
    metadata jsonb,
    before_data jsonb,
    after_data jsonb,
    ip_address text,
    user_agent text,
    created_at timestamptz not null default now()
);

create index if not exists audit_logs_created_idx on trinihub.audit_logs (created_at desc);
create index if not exists audit_logs_actor_idx on trinihub.audit_logs (actor_id);
create index if not exists audit_logs_action_idx on trinihub.audit_logs (action);
create index if not exists audit_logs_entity_idx on trinihub.audit_logs (entity_type, entity_id);

alter table trinihub.audit_logs enable row level security;

drop policy if exists audit_logs_admin_read on trinihub.audit_logs;
create policy audit_logs_admin_read on trinihub.audit_logs
    for select using (
        (auth.jwt() ->> 'app_role') = 'admin'
        or exists (
            select 1 from trinihub.user_profiles p
            where p.user_id = auth.uid()
              and (p.role = 'admin' or p.app_role = 'admin')
        )
    );

drop policy if exists audit_logs_authenticated_insert on trinihub.audit_logs;
create policy audit_logs_authenticated_insert on trinihub.audit_logs
    for insert with check (auth.role() = 'authenticated');

-- ──────────────────────────────────────────────────────────────────────────────
-- Notifications table
-- ──────────────────────────────────────────────────────────────────────────────
create table if not exists trinihub.notifications (
    id uuid primary key default uuid_generate_v4(),
    recipient_id uuid references auth.users(id) on delete cascade,
    recipient_corporation_id uuid references trinihub.corporations(id) on delete cascade,
    title text not null,
    body text,
    category text not null default 'general',
    entity_type text,
    entity_id text,
    deep_link text,
    metadata jsonb,
    read_at timestamptz,
    created_at timestamptz not null default now(),
    constraint notifications_recipient_check
        check (recipient_id is not null or recipient_corporation_id is not null)
);

create index if not exists notifications_recipient_idx on trinihub.notifications (recipient_id, created_at desc);
create index if not exists notifications_corporation_idx on trinihub.notifications (recipient_corporation_id, created_at desc);
create index if not exists notifications_unread_idx on trinihub.notifications (recipient_id) where read_at is null;

alter table trinihub.notifications enable row level security;

drop policy if exists notifications_read_own on trinihub.notifications;
create policy notifications_read_own on trinihub.notifications
    for select using (
        recipient_id = auth.uid()
        or (
            recipient_corporation_id is not null
            and recipient_corporation_id = (
                select corporation_id from trinihub.user_profiles where user_id = auth.uid()
            )
        )
        or (auth.jwt() ->> 'app_role') = 'admin'
    );

drop policy if exists notifications_update_own on trinihub.notifications;
create policy notifications_update_own on trinihub.notifications
    for update using (
        recipient_id = auth.uid()
        or (
            recipient_corporation_id is not null
            and recipient_corporation_id = (
                select corporation_id from trinihub.user_profiles where user_id = auth.uid()
            )
        )
        or (auth.jwt() ->> 'app_role') = 'admin'
    )
    with check (
        recipient_id = auth.uid()
        or (
            recipient_corporation_id is not null
            and recipient_corporation_id = (
                select corporation_id from trinihub.user_profiles where user_id = auth.uid()
            )
        )
        or (auth.jwt() ->> 'app_role') = 'admin'
    );

drop policy if exists notifications_authenticated_insert on trinihub.notifications;
create policy notifications_authenticated_insert on trinihub.notifications
    for insert with check (auth.role() = 'authenticated');

-- ──────────────────────────────────────────────────────────────────────────────
-- CivSnap municipality assignment
-- ──────────────────────────────────────────────────────────────────────────────
alter table trinihub.civsnap_reports
    add column if not exists corporation_id uuid references trinihub.corporations(id);

alter table trinihub.civsnap_reports
    add column if not exists assigned_at timestamptz;

create index if not exists civsnap_reports_corporation_idx
    on trinihub.civsnap_reports (corporation_id);

-- Allow the corp users to see reports assigned to their corporation explicitly
drop policy if exists civsnap_corp_read on trinihub.civsnap_reports;
create policy civsnap_corp_read on trinihub.civsnap_reports
    for select using (
        auth.role() = 'authenticated'
        or (
            corporation_id is not null
            and corporation_id = (
                select corporation_id from trinihub.user_profiles where user_id = auth.uid()
            )
        )
    );

-- Optional: store boundary polygons directly on corporations as GeoJSON
alter table trinihub.corporations
    add column if not exists boundary_geojson jsonb;
