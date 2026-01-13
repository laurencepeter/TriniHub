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

If you need to point the app at a different Supabase project, update the `url` and `anonKey` values in `lib/main.dart`.
          
          
