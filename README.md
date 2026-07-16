# Trini HUB

## Trinidad and Tobago solution to provide a hub to access a variety of services.

## Examples:

          - Internal Services such as File Tracking, Ticketing for the overall reduction of paper usage.
          - External Services such as The Dog Registration, report issues in the area and more.



## Features that need to be adjusted and fixed:
1. Automate reports, manual submission of reports is key time wastage factor. Weekly reports is highly inefficient and is an instant bottleneck to the process.
2. Accounts creation for the respective Corporations to login and update status of report.
3. Should have a range of other forms in one place for the persons outside the intranet to be able to fill so they can easily submit and electronic copy of the document.
4. Oversight to ensure reports submission reflects the correct Corporation and for the most accurate reason.
5. Reports will be reviewed bi-weekly generated reports to determine the overall efficiency and effectiveness of the respective Corporations.


## Server Setup 

✔️ 1. Setup VPS (Virtual Private Server). 

✔️ 2. Added Coolify (Open-Source/Self-Hosted) and linked to domain.

✔️ 3. Added Supabase (Open-Source/Self-Hosted) linked to Flutter Project (automatically pulls repo when changes are pushed to git MASTER).

✔️ 4. Added and confirmed users were authenticated (Manually). 
          ❓ Pending Features
                    :exclamation:  Add Email invitation links
                    :exclamation:  Add Social Logins

❓ 5. TODO
          :exclamation:  Add a page for fun to list all services, maybe services.fireydev.com

## Dog Registration Supabase Setup

To ensure the dog registration form inserts into the Supabase Postgres database correctly, create the required tables and policies in your Supabase project:

1. Open the Supabase SQL Editor for your project.
2. Run the schema in `supabase_dog_schema.sql` to create the `owners`, `dogs`, `dog_ownerships`, `breeds`, and `regions` tables.
3. Apply the row-level security policies in `supabase_dog_rls_policies.sql`.
4. Seed lookup data into `breeds` and `regions` so the dropdowns load in the UI.

If you need to point the app at a different Supabase project, update the environment variables in `.env` (see below).

## CivSnap Supabase Setup

To enable CivSnap issue reporting, create the required tables, storage bucket, and policies:

1. Open the Supabase SQL Editor for your project.
2. Run the schema in `supabase_civsnap_schema.sql` to create the `civsnap_reports` and `civsnap_votes` tables, plus the `civsnap` storage bucket and policies.
3. Confirm authenticated users can insert reports, votes, and upload photos to the `civsnap` bucket.

## Role claim refresh (Supabase Auth)

If you write an `app_role` value into `raw_app_meta_data`, the JWT will not update until the
client refreshes the session. Make sure the user refreshes their session after role changes:

```dart
await supabase.auth.refreshSession();
```

## Admin access troubleshooting

If admins cannot see user profiles, confirm the admin role is set on their `user_profiles` row
or in the JWT `app_role`. When using SQL to grant admin access, **you must use the auth user ID
(UUID)**, not the email address.

### Find the admin user ID (by email)
Run this in the Supabase SQL Editor (service role context is required to read `auth.users`):

```sql
select id, email
from auth.users
where email = '<ADMIN_EMAIL_HERE>';
```

If this returns **no rows**, the email does not exist in `auth.users`. Double‑check the exact
email address and that the admin has signed up in your project.

### Grant admin access using the user ID
Replace `<ADMIN_USER_ID_HERE>` with the UUID returned above:

```sql
insert into public.user_profiles (user_id, role)
values ('<ADMIN_USER_ID_HERE>', 'admin')
on conflict (user_id)
do update set role = 'admin';
```

## Local Setup

1. Create a `.env` file in the project root (or use `--dart-define`) with the following values:
   - `SUPABASE_URL=your-project-url`
   - `SUPABASE_ANON_KEY=your-anon-key`
   - `SUPABASE_RESET_REDIRECT=trinihub://recovery` (optional)

   Never put `SUPABASE_SERVICE_ROLE_KEY` in the app environment — the client
   no longer reads it. Privileged operations run in the Supabase Edge
   Functions under `supabase/functions/` (`admin-create-user`,
   `admin-update-user`), which verify the caller is an admin and keep the
   service-role key server-side. Deploy them with
   `supabase functions deploy <name>`.
2. Install dependencies:
   - `flutter pub get`
3. Run the app:
   - `flutter run`

## Auth Flow Testing

### Signup flow
1. Open the Login page and select **Create account / Register**.
2. Submit the form to create a Supabase Auth user and an Owners profile row.
3. Confirm the session routes to the home screen.

### Password reset / manual-user activation
1. From the Login page, select **Forgot password / Set password**.
2. Enter an email to trigger the password reset email.
3. Follow the link to open the in-app **Set New Password** screen and complete the reset.
   (To inspect recovery links during development, use the Supabase dashboard's
   Auth logs instead of embedding admin keys in the app.)
          
          
