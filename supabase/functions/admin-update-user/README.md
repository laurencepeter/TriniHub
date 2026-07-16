# admin-update-user

Server-side counterpart to `admin-create-user` for editing existing users.
It verifies the caller's JWT belongs to an admin (via `user_profiles`), then
uses the service-role key — which lives only in the function environment —
to update the target user's auth `app_metadata` (`role`, `app_role`,
`corporation_id`), optionally their email, and upsert their
`user_profiles` row.

This function exists so the Flutter client never needs
`SUPABASE_SERVICE_ROLE_KEY`. Shipping that key in a client build would grant
every user full database access.

## Deploy

```bash
supabase functions deploy admin-update-user
```

Required function environment variables (same as `admin-create-user`):

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (or `SUPABASE_SERVICE_KEY` / `SERVICE_SUPABASESERVICE_KEY`)

## Request

`POST` with the caller's `Authorization: Bearer <access_token>` header:

```json
{
  "user_id": "<target auth user uuid>",
  "role": "admin | corporation | corp_staff | public_user",
  "email": "optional new email",
  "display_name": "optional display name",
  "corporation_id": "optional corporation uuid",
  "organization": "optional corporation name"
}
```

## Response

- `200` `{ "ok": true, "user_id": "..." }`
- `401` caller has no valid session
- `403` caller is not an admin
- `400` validation or update failure (body contains the error)
