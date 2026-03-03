# Flutter App — Performance & Security Audit Report

**Project:** LocalAppTT (`local_app_tt`)
**Flutter SDK:** `^3.7.2` | **Supabase Flutter:** `^2.9.0`
**Audit Date:** 2026-03-03
**Branch:** `claude/flutter-audit-performance-security-N6z30`
**Scope:** All Dart source files under `lib/` (53 files)

---

## Executive Summary

The application is a multi-role civic services platform (public users, corporations, administrators) built on Flutter + Supabase. The codebase is generally well-structured, uses null safety correctly, and follows Flutter best practices in most areas. However, several **critical security issues** were found that must be addressed before any production deployment, along with a number of performance anti-patterns that will degrade responsiveness at scale.

| Severity | Security | Performance | Code Quality |
|---|---|---|---|
| Critical | 3 | — | — |
| High | 3 | 3 | — |
| Medium | 4 | 4 | 5 |
| Low | 2 | 3 | 2 |

---

## Security Findings

### CRITICAL-1 — Service Role Key Embedded in Client Code
**File:** `lib/screens/auth/forgot_password_page.dart:44–58`

```dart
final serviceKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];
final adminClient = SupabaseClient(url, serviceKey);
final response = await adminClient.auth.admin.generateLink(...)
```

The `SUPABASE_SERVICE_ROLE_KEY` is read from `.env` and instantiated as a full `SupabaseClient` inside client-side Flutter code. The service role key **bypasses all Row Level Security (RLS) policies** and grants unrestricted read/write access to the entire database. On web builds, the `.env` file is bundled into the app artefact and is trivially extractable by anyone with browser developer tools. On mobile, it can be extracted via APK/IPA inspection.

**Risk:** Full database compromise. An attacker extracting this key can read all user data, generate arbitrary auth tokens, and delete records.

**Recommendation:** All admin operations must be performed by a server-side function (e.g., Supabase Edge Function called with the user's JWT). The service role key must never appear in any Flutter file. This `_devMode` block should be removed entirely.

---

### CRITICAL-2 — Plaintext Password Displayed in SnackBar
**File:** `lib/widgets/login.dart:36`

```dart
SnackBar(
  content: Text(
    '$username Logged In Successfully!\n Protect your password $password',
  ),
)
```

The user's password is interpolated into a visible `SnackBar` message. This exposes the credential on screen and potentially in system accessibility logs or screen-reading tools.

**Risk:** Password leakage via UI; captured by screen recorders, accessibility services, or shoulder surfing.

**Recommendation:** This file (`LoginScreen`) appears to be an abandoned prototype — the production login is in `lib/widgets/loginpage.dart`. The `login.dart` file should be deleted. If kept, the SnackBar must never include credential values.

---

### CRITICAL-3 — QR Code Values Logged to Production Console
**File:** `lib/screens/qr_scannerpage.dart:65`

```dart
print('Scanned QR Code: $code');
```

`print()` in Flutter writes to the system log (`logcat` on Android, Console on iOS/macOS). In production builds, this exposes every scanned QR code value — which is used as a `fileId` — to anyone who can read device logs (other apps with `READ_LOGS` permission, USB debugging sessions, MDM tools).

**Risk:** Disclosure of internal document/file identifiers; potential for replay attacks if IDs are guessable.

**Recommendation:** Replace with `if (kDebugMode) debugPrint(...)` or remove entirely.

---

### HIGH-1 — User-Controlled Metadata Used for Role Authorisation
**File:** `lib/services/user_role_service.dart:88–95`

```dart
final metadataRole = user.appMetadata['role'] ??
    user.appMetadata['app_role'] ??
    user.userMetadata?['role'] ??       // ← user-controlled
    user.userMetadata?['app_role'];     // ← user-controlled
```

`userMetadata` is editable by the authenticated user via Supabase's `updateUser()` API. If `appMetadata` does not contain a role claim (which is the case for newly created users before an admin assigns one), the fallback reads from `userMetadata`, which the user can set to `admin` themselves.

**Risk:** Privilege escalation — a user can self-assign the `admin` role by calling `updateUser({ data: { role: 'admin' } })`.

**Recommendation:** Remove `userMetadata` fallbacks from role resolution. Role should be read exclusively from `appMetadata` (set only by server-side/admin operations) or directly from the `user_profiles` database table, which is protected by RLS.

---

### HIGH-2 — Raw Exception Messages Exposed in UI
**Files:** `lib/screens/qr_scannerpage.dart:62`, various service layers

```dart
SnackBar(content: Text('Failed to record scan: $e'))
```

Raw Dart exceptions (which can include stack traces, class names, database column names, or Postgres error messages) are displayed directly to users. This reveals internal implementation details.

**Risk:** Information disclosure — attackers can use error messages to understand database schema, infer valid IDs, or tailor further attacks.

**Recommendation:** Map all exceptions through `error_mapper.dart` (which already exists) before displaying them. Show generic messages to users; log full details only in debug mode.

---

### HIGH-3 — Unvalidated URL Rendering in Submission Detail
**File:** `lib/screens/forms/submission_detail.dart`

```dart
if (value.startsWith('http')) {
  // renders as tappable link
}
```

Form submission responses containing strings starting with `http` are rendered as tappable links without any URL validation or sanitisation. On Flutter Web, a `javascript:` URI or a maliciously crafted redirect URL in a form response could be exploited.

**Risk:** Open redirect; on web, potential XSS via `javascript:` scheme if links are opened via `url_launcher` without scheme validation.

**Recommendation:** Validate that URLs use only `https:` scheme before rendering as links. Use `Uri.parse()` and check `scheme == 'https'`.

---

### MEDIUM-1 — Predictable File Storage Paths
**File:** `lib/screens/forms/form_entry.dart` (photo uploads)

Photo files are uploaded to paths derived from predictable values (submission ID as folder). Combined with the QR code logging issue (CRITICAL-3), file IDs may be enumerable.

**Recommendation:** Use UUID-based random path components for all uploaded files. Ensure Supabase Storage bucket policies restrict access to authenticated users only.

---

### MEDIUM-2 — User-Controlled Filename in Storage Upload
**File:** `lib/services/civsnap_service.dart`

```dart
final fileName = '${report.id}/${xFile.name}';
```

`XFile.name` comes from the device file system or camera and is user-influenced. On some platforms it could include path separators (`../`).

**Recommendation:** Replace `xFile.name` with a sanitised name or a UUID with the original extension extracted safely (`path.extension(xFile.name)`).

---

### MEDIUM-3 — Dev-Mode Toggle Shipped in Production UI
**File:** `lib/screens/auth/forgot_password_page.dart:112–119`

```dart
if (kDebugMode) ...[
  SwitchListTile(
    title: const Text('Dev mode: log recovery link to console'),
    onChanged: (value) => setState(() => _devMode = value),
  ),
]
```

The UI toggle is correctly gated behind `kDebugMode`, but the underlying `_devMode` logic path (which instantiates an admin Supabase client) is not separately guarded. In a profile/release build the switch will not appear, but the code path remains compiled in and could be triggered programmatically.

**Recommendation:** Wrap the entire `_devMode` block in `assert(() { ... return true; }())` or use a compile-time constant so it is tree-shaken in release builds. Better still, remove entirely.

---

### MEDIUM-4 — Overly Permissive Email Validation
**File:** `lib/utils/validators.dart:7`

```dart
const emailRegex = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
```

This regex accepts many structurally invalid addresses (e.g., `a@b.c` with single-character TLD, double dots, or trailing dots). It also does not normalise the email to lowercase before validating or storing, which can cause duplicate account issues.

**Recommendation:** Use a stricter RFC 5321-compliant regex or the `email_validator` package. Normalise email to lowercase before submission.

---

### LOW-1 — Recovery Link Logged via `debugPrint`
**File:** `lib/screens/auth/forgot_password_page.dart:54`

```dart
debugPrint('Recovery link (dev mode): ${response.properties.actionLink}');
```

Even with `debugPrint`, this is active in debug and profile builds. Recovery links are single-use but time-limited authentication tokens. Logging them creates a window where they can be read from device logs.

**Recommendation:** Remove this entirely. Recovery link generation via the admin client should not occur client-side regardless.

---

### LOW-2 — Logout Error Leaks to User
**File:** `lib/widgets/app_drawer.dart`

Logout failure exceptions are shown directly in a SnackBar without mapping to a friendly message.

**Recommendation:** Route through `mapSupabaseError()` as other auth errors do.

---

## Performance Findings

### HIGH-P1 — Unbounded User List Fetch (No Pagination)
**File:** `lib/services/user_support_service.dart` — `fetchUsers()`

The admin user management screen fetches the complete user list from Supabase Auth Admin API in a single call. Supabase's admin user list endpoint has a hard cap of 1,000 users per request and does not stream results. The function then merges this with multiple database queries in nested loops.

**Risk:** As user count grows, this will cause progressively slower load times, increased memory usage, and potential OOM crashes.

**Recommendation:** Implement server-side pagination with `page`/`perPage` parameters. Add a search/filter endpoint instead of fetching all users and filtering client-side.

---

### HIGH-P2 — Email Verification Polling Instead of Streams
**File:** `lib/screens/auth/register_page.dart`

```dart
Timer.periodic(const Duration(seconds: 5), (timer) async {
  await _client.auth.refreshSession();
  final user = _client.auth.currentUser;
  if (user?.emailConfirmedAt != null) { ... }
});
```

A 5-second `Timer.periodic` loop actively polls the Supabase auth state to detect email verification. This approach:
- Makes unnecessary repeated network calls
- May not cancel properly if the user navigates away mid-flow
- Consumes battery on mobile

**Recommendation:** Replace with `Supabase.instance.client.auth.onAuthStateChange` stream, which delivers a `USER_UPDATED` event immediately when the email is confirmed. Cancel the stream subscription in `dispose()`.

---

### HIGH-P3 — N+1 Query Pattern in Dog Submissions
**File:** `lib/services/dog_registration_service.dart` (owner snapshot fetches)

After fetching a list of dog submissions, the service fetches owner data for each dog individually in a loop. For a list of N dogs, this results in N+1 database round trips.

**Risk:** Page load time scales linearly with submission count.

**Recommendation:** Use a Supabase `select` with an embedded join (e.g., `select('*, owner_profiles(*)')`) to fetch dogs and their owners in a single query.

---

### MEDIUM-P1 — Client-Side Geospatial Filtering
**Files:** `lib/services/civsnap_service.dart`, `lib/services/forms_service.dart`

Both services implement the Haversine formula in Dart to calculate distances from a centre point:

```dart
double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000;
  // ... full implementation
}
```

The current flow: fetch all records → compute distance for each in memory → filter. This transfers the full dataset to the client regardless of how many results are near the user.

**Risk:** Excessive data transfer and memory usage; degraded UX on slow connections.

**Recommendation:** Use Supabase's `PostGIS` extension (or a bounding-box pre-filter with lat/lon range) to filter records server-side. A simple bounding box (`WHERE latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?`) is far more efficient and requires no extension.

---

### MEDIUM-P2 — Role Fetched on Every Drawer Open
**File:** `lib/widgets/app_drawer.dart`

```dart
FutureBuilder(
  future: UserRoleService().fetchCurrentRole(),
  ...
)
```

A new `UserRoleService` instance is created and `fetchCurrentRole()` (which calls `refreshSession()` + a database query) is called every time the drawer widget is built. Because `FutureBuilder` re-triggers the future on every rebuild unless the future is stored, this can fire multiple times per navigation event.

**Recommendation:** Cache the role in a top-level provider (e.g., `InheritedWidget`, `Provider`, or `Riverpod`). The role changes infrequently — only when an admin reassigns it. A single fetch at login with an in-memory cache is sufficient.

---

### MEDIUM-P3 — No Image Size Validation Before Upload
**File:** `lib/screens/forms/form_entry.dart`

```dart
final bytes = await xFile.readAsBytes();
```

Images captured via `image_picker` are read entirely into memory as `Uint8List` before upload. No maximum file size check is performed. A user could select or capture a very large image (20–50 MB RAW on modern phones), causing an OOM error or very slow upload.

**Recommendation:** Check `xFile.length()` before reading. Enforce a maximum (e.g., 10 MB). Consider using `image_picker`'s `imageQuality` and `maxWidth`/`maxHeight` parameters to compress on capture.

---

### MEDIUM-P4 — Multiple Redundant Dashboard Fetches on Re-navigation
**File:** `lib/screens/admin_dashboard.dart`

The admin dashboard triggers several `Future`-based data fetches in `initState`. Navigating away and back recreates the widget, causing all fetches to re-fire with no caching layer.

**Recommendation:** Lift state into a service or provider layer so dashboard data survives widget rebuilds. Add a pull-to-refresh mechanism for explicit user-initiated refreshes.

---

### LOW-P1 — `FutureBuilder` Without Stored Future Reference
Multiple screens construct the future inline in `build()`:

```dart
FutureBuilder(
  future: someService.fetchData(), // new Future on every build
```

When the parent widget rebuilds (e.g., theme change, keyboard open), a new `Future` is started, causing visible loading flickers.

**Recommendation:** Store the `Future` in a `State` field and assign it in `initState()` so it is stable across rebuilds.

---

### LOW-P2 — Redundant `setState` Calls After Async Operations
Several widgets call `setState(() {})` after async operations without checking whether the state has actually changed. This triggers unnecessary widget tree rebuilds.

---

### LOW-P3 — Magic Numbers Throughout Services
**Files:** `lib/services/civsnap_service.dart`, `lib/services/dog_registration_service.dart`

Hard-coded values like page sizes (`200`), timeout durations, and radius defaults appear inline without named constants. These are difficult to tune and easy to miss.

**Recommendation:** Define them as `static const` values at the class level.

---

## Code Quality / Architecture Findings

### Dead Code — Prototype Files in Production

| File | Issue |
|---|---|
| `lib/widgets/login.dart` | Legacy `LoginScreen` prototype. Not referenced in routing. Contains the CRITICAL-2 password SnackBar. Should be deleted. |
| `lib/screens/test.dart` | `TestApp` / `HomeScreen` — a theme toggle sandbox. Not referenced in routing. Should be deleted or moved to `test/`. |

These files are compiled into production builds, increasing bundle size and presenting maintenance risk.

---

### Role Authorisation Relies on Soft Guard Only
**File:** `lib/widgets/admin_gate.dart`, `lib/widgets/role_gate.dart`

Administrative UI is hidden from non-admin users via client-side role gates. This is appropriate for UX, but the underlying Supabase data access (RLS policies) must be the authoritative security layer. The audit could not verify RLS policy coverage from Flutter code alone.

**Recommendation:** Confirm that all `user_profiles`, `civsnap_reports`, `dog_registrations`, and `forms` tables have RLS policies that prevent cross-user data access even if the client-side gates are bypassed.

---

### `AuthService.signIn` Does Not Validate Email Format
**File:** `lib/services/auth_service.dart:57`

`signIn()` accepts the email string directly without trimming or format validation. The `loginpage.dart` does call `Validators.email()` before invoking `signIn()`, but since `AuthService` is a public class, direct callers bypass validation.

**Recommendation:** Add `email.trim()` inside `signIn()` and `signUp()` at the service level as a defence-in-depth measure.

---

### Missing `dispose()` for Timer in Registration Flow
**File:** `lib/screens/auth/register_page.dart`

The email verification polling `Timer` should be explicitly cancelled in `dispose()` to prevent callbacks firing on an unmounted widget. While there are `mounted` guards before `setState` calls, the timer itself will continue running and making network requests until the garbage collector finalises the state object.

---

## Summary Table

| ID | File | Severity | Category | Description |
|---|---|---|---|---|
| CRITICAL-1 | `forgot_password_page.dart:44` | Critical | Security | Service role key in client code |
| CRITICAL-2 | `widgets/login.dart:36` | Critical | Security | Password in SnackBar |
| CRITICAL-3 | `qr_scannerpage.dart:65` | Critical | Security | QR codes logged via `print()` |
| HIGH-1 | `user_role_service.dart:88` | High | Security | User metadata used for role auth |
| HIGH-2 | `qr_scannerpage.dart:62` | High | Security | Raw exceptions shown to users |
| HIGH-3 | `submission_detail.dart` | High | Security | Unvalidated URL rendering |
| MEDIUM-1 | `form_entry.dart` | Medium | Security | Predictable file storage paths |
| MEDIUM-2 | `civsnap_service.dart` | Medium | Security | User-controlled upload filename |
| MEDIUM-3 | `forgot_password_page.dart:112` | Medium | Security | Dev mode compiled into release |
| MEDIUM-4 | `validators.dart:7` | Medium | Security | Weak email validation regex |
| LOW-1 | `forgot_password_page.dart:54` | Low | Security | Recovery link in `debugPrint` |
| LOW-2 | `app_drawer.dart` | Low | Security | Raw logout error to user |
| HIGH-P1 | `user_support_service.dart` | High | Performance | Unbounded user list, no pagination |
| HIGH-P2 | `register_page.dart` | High | Performance | Polling timer vs auth stream |
| HIGH-P3 | `dog_registration_service.dart` | High | Performance | N+1 query for owner data |
| MEDIUM-P1 | `civsnap_service.dart` | Medium | Performance | Client-side geospatial filtering |
| MEDIUM-P2 | `app_drawer.dart` | Medium | Performance | Role fetched on every drawer open |
| MEDIUM-P3 | `form_entry.dart` | Medium | Performance | No image size limit before upload |
| MEDIUM-P4 | `admin_dashboard.dart` | Medium | Performance | No caching on re-navigation |
| LOW-P1 | Multiple screens | Low | Performance | `FutureBuilder` with unstored future |
| LOW-P2 | Multiple screens | Low | Performance | Redundant `setState` calls |
| LOW-P3 | Multiple services | Low | Performance | Magic numbers (page sizes, radii) |
| QA-1 | `widgets/login.dart` | Medium | Code Quality | Dead prototype file in production |
| QA-2 | `screens/test.dart` | Medium | Code Quality | Test scaffold file in production `lib/` |
| QA-3 | `admin_gate.dart` | Medium | Code Quality | RLS policy coverage not verifiable from client |
| QA-4 | `auth_service.dart:57` | Low | Code Quality | No email trim/validation at service layer |
| QA-5 | `register_page.dart` | Low | Code Quality | Timer not cancelled in `dispose()` |

---

## Recommended Remediation Priority

1. **Immediate (before next production release)**
   - CRITICAL-1: Remove `SUPABASE_SERVICE_ROLE_KEY` from client code entirely
   - CRITICAL-2: Delete `lib/widgets/login.dart`
   - CRITICAL-3: Remove `print()` in `qr_scannerpage.dart`
   - HIGH-1: Remove `userMetadata` role fallbacks

2. **Short-term (next sprint)**
   - HIGH-2: Route all exceptions through `error_mapper.dart`
   - HIGH-3: Validate URL scheme before rendering links
   - HIGH-P1: Add pagination to user management
   - HIGH-P2: Replace polling with `onAuthStateChange` stream
   - HIGH-P3: Replace N+1 queries with embedded joins
   - QA-1/QA-2: Delete dead files (`login.dart`, `test.dart`)

3. **Medium-term (backlog)**
   - All MEDIUM severity items

---

*Report generated by automated audit on branch `claude/flutter-audit-performance-security-N6z30`.*
