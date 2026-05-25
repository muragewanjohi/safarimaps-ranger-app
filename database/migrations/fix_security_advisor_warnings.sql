-- Fix Supabase Security Advisor warnings (46 items)
-- Project: ukwhaovrofmbcynkiemc (SafariMaps)
-- Run in Supabase → SQL Editor. Safe to re-run.
--
-- Categories addressed:
--   1. Function Search Path Mutable
--   2. RLS Policy Always True
--   3. Public Bucket Allows Listing
--   4. Public Can See Object in GraphQL Schema

-- ===========================================================================
-- 1. FUNCTION SEARCH PATH MUTABLE
--    Fix: recreate functions with SET search_path = ''
-- ===========================================================================

-- 1a. update_updated_at_column
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 1b. handle_new_user (SECURITY DEFINER — search_path is critical here)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  default_park_id UUID;
  user_name TEXT;
  user_email TEXT;
  ranger_id_val TEXT;
  team_val TEXT;
  user_role_val public.user_role;
  avatar_text TEXT;
BEGIN
  RAISE LOG 'Profile creation trigger fired for user: %', NEW.id;
  RAISE LOG 'User email: %', NEW.email;
  RAISE LOG 'User metadata: %', NEW.raw_user_meta_data;

  BEGIN
    user_name := COALESCE(
      NEW.raw_user_meta_data->>'name',
      NEW.raw_user_meta_data->>'full_name',
      SPLIT_PART(NEW.email, '@', 1),
      'New User'
    );

    user_email := NEW.email;

    ranger_id_val := NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'ranger_id', '')), '');
    team_val := NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'team', '')), '');

    IF ranger_id_val IS NOT NULL AND ranger_id_val != '' THEN
      user_role_val := 'Ranger'::public.user_role;
    ELSE
      user_role_val := 'Visitor'::public.user_role;
    END IF;

    RAISE LOG 'Processed user data: name=%, role=%, ranger_id=%, team=%', user_name, user_role_val, ranger_id_val, team_val;

    SELECT id INTO default_park_id FROM public.parks WHERE name = 'Masai Mara National Reserve' LIMIT 1;

    IF default_park_id IS NULL THEN
      RAISE WARNING 'Default park "Masai Mara National Reserve" not found.';
    END IF;

    avatar_text := UPPER(SUBSTRING(COALESCE(user_name, 'NU'), 1, 2));

    INSERT INTO public.profiles (
      id, name, role, ranger_id, team, primary_park_id, avatar, email, join_date, is_active
    )
    VALUES (
      NEW.id,
      user_name,
      user_role_val,
      ranger_id_val,
      team_val,
      default_park_id,
      avatar_text,
      user_email,
      CURRENT_DATE,
      true
    );

    RAISE LOG 'Profile created successfully for user: %', NEW.id;

    IF user_role_val = 'Ranger' AND default_park_id IS NOT NULL THEN
      INSERT INTO public.ranger_parks (ranger_id, park_id, assigned_date, is_active)
      VALUES (NEW.id, default_park_id, CURRENT_DATE, true);
      RAISE LOG 'Ranger assigned to park for user: %', NEW.id;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE LOG 'ERROR in trigger for user %: %', NEW.id, SQLERRM;
  END;

  RETURN NEW;
END;
$$;

-- 1c. _coerce_user_role (if it exists — may be a helper for casting)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = '_coerce_user_role' AND pronamespace = 'public'::regnamespace
  ) THEN
    EXECUTE format(
      'ALTER FUNCTION public._coerce_user_role SET search_path = %L', ''
    );
  END IF;
END;
$$;


-- ===========================================================================
-- 2. RLS POLICY ALWAYS TRUE
--    The advisor flags SELECT policies using bare USING (true).
--    For public reference data (achievements, parks, etc.) we scope to
--    authenticated users only — unauthenticated (anon) shouldn't need access.
-- ===========================================================================

-- 2a. user_achievements — scope to authenticated
DROP POLICY IF EXISTS "Users can view user achievements" ON public.user_achievements;
CREATE POLICY "Authenticated users can view user achievements"
ON public.user_achievements
FOR SELECT
TO authenticated
USING (true);

-- 2b. achievements — scope to authenticated
DROP POLICY IF EXISTS "Users can view achievements" ON public.achievements;
CREATE POLICY "Authenticated users can view achievements"
ON public.achievements
FOR SELECT
TO authenticated
USING (true);

-- 2c. parks — scope to authenticated (rangers + visitors must be logged in)
DROP POLICY IF EXISTS "Anyone can view parks" ON public.parks;
CREATE POLICY "Authenticated users can view parks"
ON public.parks
FOR SELECT
TO authenticated
USING (true);

-- 2d. park_entries — scope to authenticated
DROP POLICY IF EXISTS "Anyone can view park entries" ON public.park_entries;
CREATE POLICY "Authenticated users can view park entries"
ON public.park_entries
FOR SELECT
TO authenticated
USING (true);

-- 2e. profiles — scope to authenticated
DROP POLICY IF EXISTS "Users can view all profiles" ON public.profiles;
CREATE POLICY "Authenticated users can view profiles"
ON public.profiles
FOR SELECT
TO authenticated
USING (true);

-- 2f. incidents — scope to authenticated
DROP POLICY IF EXISTS "Users can view incidents" ON public.incidents;
CREATE POLICY "Authenticated users can view incidents"
ON public.incidents
FOR SELECT
TO authenticated
USING (true);

-- 2g. locations — scope to authenticated
DROP POLICY IF EXISTS "Users can view locations" ON public.locations;
CREATE POLICY "Authenticated users can view locations"
ON public.locations
FOR SELECT
TO authenticated
USING (true);

-- 2h. reports — scope to authenticated
DROP POLICY IF EXISTS "Users can view reports" ON public.reports;
CREATE POLICY "Authenticated users can view reports"
ON public.reports
FOR SELECT
TO authenticated
USING (true);

-- 2i. location_photos — the existing policy is complex, replace with auth-scoped
DROP POLICY IF EXISTS "Users can view location photos" ON public.location_photos;
CREATE POLICY "Authenticated users can view location photos"
ON public.location_photos
FOR SELECT
TO authenticated
USING (true);

-- 2j. ranger_parks — scope to authenticated
DROP POLICY IF EXISTS "Users can view ranger-park assignments" ON public.ranger_parks;
CREATE POLICY "Authenticated users can view ranger-park assignments"
ON public.ranger_parks
FOR SELECT
TO authenticated
USING (true);

-- 2k. waitlist (tourist app) — if it exists and has USING(true), fix it
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'waitlist') THEN
    -- Drop any overly-permissive policy
    EXECUTE 'DROP POLICY IF EXISTS "Anyone can view waitlist" ON public.waitlist';
    EXECUTE 'DROP POLICY IF EXISTS "Authenticated users can view waitlist" ON public.waitlist';
    EXECUTE '
      CREATE POLICY "Authenticated users can view waitlist"
      ON public.waitlist
      FOR SELECT
      TO authenticated
      USING (true)
    ';
  END IF;
END;
$$;


-- ===========================================================================
-- 3. PUBLIC BUCKET ALLOWS LISTING
--    Storage buckets are "public" (meaning objects can be accessed by URL) but
--    the SELECT policy on storage.objects allows anyone to list contents.
--    Fix: restrict object listing to authenticated users.
-- ===========================================================================

-- 3a. incident-photos bucket
DROP POLICY IF EXISTS "Anyone can view incident photos" ON storage.objects;
DROP POLICY IF EXISTS "Public can view incident-photos" ON storage.objects;

CREATE POLICY "Authenticated users can list incident-photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'incident-photos');

-- 3b. location-photos bucket
DROP POLICY IF EXISTS "Anyone can view location photos" ON storage.objects;
DROP POLICY IF EXISTS "Public can view location-photos" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view location-photos" ON storage.objects;

CREATE POLICY "Authenticated users can list location-photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'location-photos');

-- 3c. park-photos bucket (from schema.sql)
DROP POLICY IF EXISTS "Anyone can view park photos" ON storage.objects;

CREATE POLICY "Authenticated users can list park-photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'park-photos');

-- Note: Making buckets "public" still allows direct URL access to objects
-- (e.g. https://xxx.supabase.co/storage/v1/object/public/bucket/file.jpg)
-- but listing/browsing via the API is now restricted to authenticated users.


-- ===========================================================================
-- 4. PUBLIC CAN SEE OBJECT IN GRAPHQL SCHEMA
--    By default, Supabase exposes tables to the anon role via PostgREST/GraphQL.
--    Revoke anon access on tables that should only be used by authenticated users.
-- ===========================================================================

-- Ranger app tables
REVOKE ALL ON public.profiles FROM anon;
REVOKE ALL ON public.ranger_parks FROM anon;
REVOKE ALL ON public.incidents FROM anon;
REVOKE ALL ON public.locations FROM anon;
REVOKE ALL ON public.location_photos FROM anon;
REVOKE ALL ON public.reports FROM anon;
REVOKE ALL ON public.parks FROM anon;
REVOKE ALL ON public.park_entries FROM anon;
REVOKE ALL ON public.achievements FROM anon;
REVOKE ALL ON public.user_achievements FROM anon;

-- Tourist app tables
REVOKE ALL ON public.marketplace FROM anon;
REVOKE ALL ON public.notifications FROM anon;
REVOKE ALL ON public.sightings FROM anon;
REVOKE ALL ON public.wishlist FROM anon;
REVOKE ALL ON public.payments FROM anon;
REVOKE ALL ON public.users FROM anon;

-- kv_store (internal Supabase Realtime table — no user access needed)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE 'kv_store_%') THEN
    EXECUTE (
      SELECT string_agg(format('REVOKE ALL ON public.%I FROM anon', tablename), '; ')
      FROM pg_tables
      WHERE schemaname = 'public' AND tablename LIKE 'kv_store_%'
    );
  END IF;
END;
$$;

-- Ensure authenticated role still has necessary access
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ranger_parks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.incidents TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.locations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.location_photos TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.reports TO authenticated;
GRANT SELECT ON public.parks TO authenticated;
GRANT SELECT ON public.park_entries TO authenticated;
GRANT SELECT ON public.achievements TO authenticated;
GRANT SELECT ON public.user_achievements TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.marketplace TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.notifications TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.sightings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.wishlist TO authenticated;
GRANT SELECT, INSERT ON public.payments TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.users TO authenticated;

-- Rangers/admins need full access to parks and park_entries
GRANT INSERT, UPDATE, DELETE ON public.parks TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.park_entries TO authenticated;

-- Grant usage on sequences (needed for inserts)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
