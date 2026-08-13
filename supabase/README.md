# TriniHub Supabase schema

This directory holds the full database schema as ordered, timestamped
migrations that the [Supabase CLI](https://supabase.com/docs/guides/cli)
applies in filename order. It replaces the loose `supabase_*.sql` files that
used to live in the repository root — each of those has been moved into a
migration here (see the mapping table below).

```
supabase/
├── config.toml                 # Supabase CLI project config
├── seed.sql                    # admin bootstrap (edit the email, then run)
├── migrations/                 # ordered schema migrations (apply in order)
└── functions/                  # edge functions (unchanged)
```

## Applying the schema

**To a hosted project:**

```bash
supabase link --project-ref <your-project-ref>
supabase db push          # applies every migration not yet on the remote
```

**To a fresh local stack:**

```bash
supabase start
supabase db reset         # runs all migrations, then seed.sql
```

**Without the CLI:** open each file in `migrations/` in the Supabase SQL
editor and run them **in filename order** (they are numbered so lexical order
is the correct apply order).

## Migration order

| # | File | Provides |
|---|------|----------|
| 1 | `20240101000000_foundation.sql` | `corporations`, `user_profiles`, `my_profile` view, self-service RLS *(reconstructed — see note)* |
| 2 | `20240101000100_file_scans.sql` | `files`, `departments`, `file_scans`, `admin_users_view`, `admin_list_users()` |
| 3 | `20240101000200_file_custody_tracking.sql` | custody columns + policies on `file_scans` |
| 4 | `20240101000300_dog_registry.sql` | `regions`, `breeds`, `owners`, `dogs`, `dog_ownerships` |
| 5 | `20240101000400_civsnap.sql` | `civsnap_reports`, `civsnap_votes`, `civsnap` storage bucket |
| 6 | `20240101000500_civsnap_access.sql` | `user_roles`, corp/admin status-update policy |
| 7 | `20240101000600_civsnap_corporation_assignment.sql` | corporation assignment columns on reports |
| 8 | `20240101000700_forms.sql` | `form_templates`, `form_fields`, `form_submissions`, `form_submission_media`, `form-uploads` bucket, role helper functions |
| 9 | `20240101000800_issues.sql` | `issues`, `issue_reports`, `issue_votes`, `issue_popularity` view |
| 10 | `20240101000900_audit_notifications.sql` | `audit_logs`, `notifications`, civsnap municipality assignment, `corporations.boundary_geojson` |
| 11 | `20240101001000_user_profiles_organization.sql` | `user_profiles.organization` + backfill |
| 12 | `20240101001100_admin_policies.sql` | `is_admin()` + admin-manage policy on `user_profiles` |
| 13 | `20240101001200_dog_rls_policies.sql` | RLS for the dog registry (uses `is_admin()`) |
| 14 | `20240101001300_bug_reports.sql` | `bug_reports` (Internal/External "Report a Bug"), severity/status enums, reporter + admin RLS |

Dependencies are why the order matters — e.g. `is_admin()` (12) must exist
before the dog policies (13) that call it; `corporations`/`user_profiles` (1)
must exist before the forms, notifications, and civsnap-assignment migrations
that reference them.

## Old file → new migration mapping

| Old root file | New migration |
|---------------|---------------|
| *(none — reconstructed)* | `20240101000000_foundation.sql` |
| `supabase_schema.sql` | `20240101000100_file_scans.sql` |
| `supabase_file_custody_schema.sql` | `20240101000200_file_custody_tracking.sql` |
| `supabase_dog_schema.sql` | `20240101000300_dog_registry.sql` |
| `supabase_civsnap_schema.sql` | `20240101000400_civsnap.sql` |
| `supabase_civsnap_access_schema.sql` | `20240101000500_civsnap_access.sql` |
| `supabase_civsnap_corporation_assignment.sql` | `20240101000600_civsnap_corporation_assignment.sql` |
| `supabase_forms_schema.sql` | `20240101000700_forms.sql` |
| `supabase_issue_schema.sql` | `20240101000800_issues.sql` |
| `supabase_audit_notifications_schema.sql` | `20240101000900_audit_notifications.sql` |
| `supabase_user_profiles_organization.sql` | `20240101001000_user_profiles_organization.sql` |
| `supabase_admin_policies.sql` | `20240101001100_admin_policies.sql` |
| `supabase_dog_rls_policies.sql` | `20240101001200_dog_rls_policies.sql` |
| `supabase_admin_bootstrap.sql` | `seed.sql` |

## Notes on changes made during reorganization

These are the only behavioral differences from the original scripts; every
other statement was carried over verbatim:

1. **Reconstructed foundation (`20240101000000_foundation.sql`).**
   `corporations` and `user_profiles` were referenced everywhere (foreign
   keys, RLS, the admin view/RPC, and the Flutter services) but never had a
   `CREATE TABLE` in the original scripts — they were created by hand in the
   Supabase dashboard. Their definitions here are inferred from usage so a
   fresh project builds end-to-end. **Compare them against your live database
   before pushing to an existing project.**

2. **Invalid enum syntax fixed (`20240101000800_issues.sql`).** The original
   used `create type if not exists …`, which PostgreSQL rejects for enum
   types and would abort a clean run. The enums are now created inside guarded
   `DO` blocks.

3. **Idempotency.** `drop … if exists` guards were added ahead of the
   `create policy` / `create trigger` statements that lacked them, so a
   migration can be re-applied without erroring on already-present objects.

## Applying to another project

Point the CLI at the other project (`supabase link --project-ref <ref>`) and
run `supabase db push`. If that project already has some of these objects,
review migration 1 first and delete or adjust any table it would duplicate —
the rest use `if not exists` / `if exists` guards and are safe to re-run.
Remember the app also expects two storage buckets (`civsnap`, `form-uploads`,
created by migrations 5 and 8) and the two edge functions under `functions/`.
