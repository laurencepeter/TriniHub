# TriniHub — Platform Rollout Audit & Readiness

**Date:** 2026-08-13
**Branch:** `claude/audit-security-platform-rollout-m0z08k`
**Scope:** Audit-logging verification, data-safety status, bug-reporting wiring, and the
remaining Internal/External feature gaps blocking a full rollout.

This document accompanies the earlier `AUDIT_REPORT.md` (2026-03-03). It records what
has changed since then, verifies the audit trail, and lists what still has to be done.

---

## 1. Audit table — verified ✅ (present, but coverage is partial)

**There is an audit table, and the app writes to it.** It is not missing.

| Component | Location | Status |
|---|---|---|
| Table `public.audit_logs` | `supabase/migrations/20240101000900_audit_notifications.sql` | ✅ Present |
| Write API | `lib/services/audit_log_service.dart` → `record(...)` | ✅ Present |
| Read/filter API | `AuditLogService.fetchLogs()` / `fetchActions()` | ✅ Present |
| Admin viewer UI | `lib/screens/audit_logs.dart` (opened from the app drawer) | ✅ Present |
| RLS | admin-only read; authenticated insert | ✅ Enforced |

**Schema** captures actor (`actor_id`, `actor_email`, `actor_role`), `action`,
`entity_type`/`entity_id`, `summary`, `metadata`, `before_data`/`after_data`, plus
`ip_address`/`user_agent` columns and a `created_at` index. That is a solid design for a
tamper-evident trail.

### Coverage gap — "logs of everything" is not yet true

The requirement is *logs of everything happening on the platform.* Today only **10**
call sites write to `audit_logs`. What is and isn't logged:

| Flow | Logged? |
|---|---|
| User create / update / role delete (admin) | ✅ Yes |
| CivSnap report submit / status change / assignment | ✅ Yes |
| Forms: submit / template / status change | ✅ Yes |
| **Bug reports** (this change) | ✅ Yes (new) |
| **Dog registration** submit/approve | ❌ No |
| **File custody** scans (received / checked-out / transferred) | ❌ No |
| **Auth events** (sign-in, sign-out, password reset) | ❌ No |
| Notifications read/dismiss | ❌ No |

**Recommendation (rollout blocker for a true audit trail):** add
`AuditLogService.instance.record(...)` calls to `dog_registration_service.dart`,
`file_scan_service.dart`, and the auth flow (`auth_service.dart`). Better still, move
audit writes to **database triggers** (`AFTER INSERT/UPDATE/DELETE`) on the sensitive
tables so the trail cannot be bypassed by a client that simply omits the call, and so
`ip_address`/`user_agent` are captured server-side rather than left null. The
client-side `record()` helper is best-effort by design (it swallows its own errors so it
never breaks a flow) — which is correct for UX but means it must **not** be the only
guarantee.

---

## 2. User & data safety — status since the March audit

Several items from `AUDIT_REPORT.md` are now fixed; the rest are tracked below.

### Fixed in this change

| ID | Item | Fix |
|---|---|---|
| CRITICAL-2 | Plaintext password shown in a SnackBar (`widgets/login.dart`) | **File deleted** (dead prototype, unreferenced) |
| CRITICAL-3 | Scanned QR/file IDs logged via `print()` | Gated behind `kDebugMode` + `debugPrint` |
| HIGH-1 | Privilege escalation: role read from user-editable `userMetadata` | Removed `userMetadata` fallback in `user_role_service.dart` (both paths) and `audit_log_service.dart`; role now comes from the server-controlled JWT `app_role` claim or the RLS-protected `user_profiles` table only |
| QA-2 | Theme-sandbox `screens/test.dart` compiled into production | **File deleted** |

### Already fixed before this change (verified)

- **CRITICAL-1** — the `SUPABASE_SERVICE_ROLE_KEY` client is gone from
  `forgot_password_page.dart`; admin operations run in the `admin-create-user` /
  `admin-update-user` Edge Functions.
- **HIGH-2** — `qr_scannerpage.dart` now routes exceptions through `mapSupabaseError()`.

### Still open (recommend before/shortly after rollout)

| ID | Item | Where |
|---|---|---|
| HIGH-3 | Unvalidated URL rendering (allow only `https:` scheme) | `forms/submission_detail.dart` |
| MEDIUM-1/2 | Predictable / user-controlled storage paths → use UUID paths | `form_entry.dart`, `civsnap_service.dart` |
| MEDIUM-4 | Weak email regex; normalise to lowercase | `utils/validators.dart` |
| QA-3 | **Verify RLS coverage on every table** end-to-end (client gates are UX only) | all tables |

### Data-at-rest / data-safety notes

- **RLS is the real security boundary.** Foundation, admin, dog, civsnap, forms,
  issues, notifications, audit, and the new bug-reports migrations all
  `enable row level security` with explicit policies. Confirm in the live project that
  **no table** was left with RLS disabled or a blanket `using (true)` write policy.
- The `issues` table intentionally allows anonymous public read/insert (community
  reporting). `bug_reports` (new) is stricter: **authenticated insert as self only**,
  reporter-or-admin read, admin-only update/delete.
- Edge functions `admin-create-user` / `admin-update-user` run with `verify_jwt = false`
  and **re-verify admin inside the function** — confirm that internal check is present
  and cannot be skipped, since JWT verification is delegated to the function body.
- Ensure Supabase Storage buckets (`civsnap`, `form-uploads`) have policies restricting
  object access to authenticated users; do not rely on unguessable paths alone.

---

## 3. Bug reporting — now wired to the database ✅

**Before:** the "Report a Bug" tiles (Internal *and* External) opened
`ServiceDetailScreen`, whose "Submit request" button only flipped a local boolean to
show a fake success panel. **Everything the user typed was discarded — nothing reached
the database.**

**After (this change):**

- **New table** `public.bug_reports` — `supabase/migrations/20240101001300_bug_reports.sql`
  (scope, title, description, module, `severity` + `status` enums, reporter identity,
  contact email, platform / app-version / device metadata, resolution notes, timestamps,
  indexes, `updated_at` trigger, and RLS).
- **New service** `lib/services/bug_report_service.dart` — `submit(...)` inserts the
  report and mirrors a `bug_report.created` entry into `audit_logs`; `fetchReports(...)`
  reads them back (own reports, or all for admins, via RLS).
- **New screen** `lib/screens/report_bug.dart` — a real validated form (title required,
  optional contact email validated, severity picker, steps-to-reproduce) with loading /
  error / success states and a reference ID.
- **Wiring** `lib/data/service_catalog.dart` — both `handleExternalServiceTap` and
  `handleInternalServiceTap` now route "Report a Bug" to `ReportBugScreen`.

**Apply the SQL:** `supabase db push` (hosted) or `supabase db reset` (local) — it is
migration #14 and depends only on already-present objects (`set_updated_at`, `is_admin`).

**Follow-ups (not blocking):** an admin triage list/screen reading `fetchReports()` (the
data + RLS already support it), optional screenshot upload to a private bucket, and email
notification to the support inbox on new critical bugs.

---

## 4. Internal & External services — rollout gap matrix

Derived from `lib/data/service_catalog.dart` tap handlers. "Real" = routes to a working,
DB-backed screen; "Mock" = routes to the placeholder `ServiceDetailScreen`.

### External Services

| Tile | Status | Notes |
|---|---|---|
| Dog Registration | ✅ Real | `DogRegistrationScreen` |
| Scan File | ✅ Real | `FileCustodyHub` |
| Forms | ✅ Real | `FormsHubScreen(public)` |
| CivSnap | ✅ Real | `CivSnapPortalScreen` |
| Report a Bug | ✅ Real (**new**) | now DB-backed |
| **Find File** | ❌ **Mock** | placeholder form only — no search backend |

### Internal Services

| Tile | Status | Notes |
|---|---|---|
| Scan File | ✅ Real | `FileCustodyHub` |
| Forms | ✅ Real | `FormsHubScreen(internal)` |
| Report a Bug | ✅ Real (**new**) | now DB-backed |
| **Find File** | ❌ **Mock** | placeholder form only — no search backend |

### The one remaining non-functional feature: **Find File** (both catalogs)

It is the last tile still pointing at the mock `ServiceDetailScreen`. To make it real it
needs:

1. A search API over the existing `public.files` / `file_scans` tables (record ID, title,
   department, custody status) — ideally a Postgres function or a `to_tsvector` full-text
   index, plus RLS so internal vs public scope returns the right rows.
2. A `FileSearchService` + results screen (mirroring the bug-report pattern used here).
3. Audit logging of file-access requests (ties back to §1).

Until then, either implement it or **hide the Find File tile** so the rollout doesn't ship
a dead-end form.

### Cross-cutting rollout blockers (apply to the whole platform)

- **Audit coverage** (§1): log dog registration, file custody, and auth events.
- **Security backlog** (§2): HIGH-3 URL validation, storage-path hardening, email
  validation, and a full RLS review.
- **Performance at scale** (from `AUDIT_REPORT.md`, still open): admin user list needs
  pagination (`user_support_service.dart`), replace the register-page polling timer with
  `onAuthStateChange`, and fix the N+1 owner fetch in `dog_registration_service.dart`.

---

## 5. Networking / deployment architecture (as described)

The intended topology — **reverse proxy in the DMZ → front end → API layer → database** —
is sound. Notes to make it real with this Supabase-backed app:

- **The database must never be reachable from the DMZ or the client directly.** With
  Supabase, the browser/app talks to Supabase over HTTPS; RLS is what makes that safe, so
  the RLS review in §2/§4 is the load-bearing control, not the network diagram.
- The reverse proxy (e.g. Nginx/Traefik) in the DMZ should terminate TLS, add security
  headers (HSTS, CSP, `X-Content-Type-Options`), and forward only to the app/API — not to
  Postgres.
- Keep **all privileged operations behind the API/Edge-Function tier** (as the admin user
  functions already are). The service-role key lives only server-side (confirmed removed
  from the client in §2).
- Capture `ip_address` / `user_agent` for the audit trail at the API/proxy tier and pass
  them through, since the columns already exist but are currently null from the client.

---

## Summary of changes in this branch

| Type | Path |
|---|---|
| Added | `supabase/migrations/20240101001300_bug_reports.sql` |
| Added | `lib/services/bug_report_service.dart` |
| Added | `lib/screens/report_bug.dart` |
| Added | `PLATFORM_ROLLOUT_AUDIT.md` (this file) |
| Changed | `lib/data/service_catalog.dart` (wire Report a Bug → real screen) |
| Changed | `lib/services/user_role_service.dart` (drop userMetadata role fallback) |
| Changed | `lib/services/audit_log_service.dart` (drop userMetadata actor role) |
| Changed | `lib/screens/qr_scannerpage.dart` (gate QR log behind kDebugMode) |
| Changed | `supabase/README.md` (migration table row 14) |
| Deleted | `lib/widgets/login.dart` (plaintext-password SnackBar) |
| Deleted | `lib/screens/test.dart` (theme sandbox) |
