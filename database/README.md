# SafariMap Database

Database schema and migrations for the SafariMap project (shared by ranger + tourist apps).

## Files

- `schema.sql` — Full GameWarden schema (ranger app tables, RLS, triggers, seed data)
- `migrations/` — Incremental SQL patches to run in Supabase SQL Editor
  - `fix_location_photos_rls.sql` — Fixes ranger add-location photo upload RLS error
  - `enable_public_tourist_tables_rls.sql` — Enables RLS on tourist-app tables (`users`, `sightings`, `wishlist`, `marketplace`, `payments`, `notifications`)

## How to apply

1. Open [Supabase SQL Editor](https://supabase.com/dashboard/project/ukwhaovrofmbcynkiemc/sql)
2. Paste and run the relevant `.sql` file
3. Verify in **Security Advisor** (Dashboard → Security) that errors are cleared
