# admin-create-user Edge Function

Use the Supabase CLI to set secrets and deploy the function from this repo.

## 1) Login and link your project

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

## 2) Set required secrets

```bash
supabase secrets set \
  SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co" \
  SUPABASE_ANON_KEY="YOUR_SUPABASE_ANON_KEY" \
  SUPABASE_SERVICE_ROLE_KEY="YOUR_SUPABASE_SERVICE_ROLE_KEY"
```

## 3) Deploy the function

```bash
supabase functions deploy admin-create-user
```

## 4) Call the function (example)

```bash
curl -i \
  -H "Authorization: Bearer YOUR_ADMIN_JWT" \
  -H "Content-Type: application/json" \
  -X POST \
  --data '{
    "email": "new.user@example.com",
    "temp_password": "TempPass123!",
    "role": "corporation",
    "organization": "Central Region",
    "region_code": "YOUR_REGION_CODE"
  }' \
  "https://YOUR_PROJECT_REF.supabase.co/functions/v1/admin-create-user"
```

## 5) Verify logs (optional)

```bash
supabase functions logs admin-create-user
```
