-- Enable Row Level Security on tourist-app tables flagged by Supabase Security Advisor.
-- Project: ukwhaovrofmbcynkiemc (SafariMaps)
--
-- Fixes "RLS Disabled in Public" for:
--   public.users, public.sightings, public.wishlist,
--   public.marketplace, public.payments, public.notifications
--
-- Run in Supabase → SQL Editor. Safe to re-run (policies use DROP IF EXISTS).
--
-- Optional: inspect columns before applying
-- SELECT table_name, column_name, data_type
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
--   AND table_name IN ('users','sightings','wishlist','marketplace','payments','notifications')
-- ORDER BY table_name, ordinal_position;

-- ---------------------------------------------------------------------------
-- users (tourist profiles — separate from ranger "profiles" table)
-- ---------------------------------------------------------------------------
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can view user profiles" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;

CREATE POLICY "Authenticated users can view user profiles"
ON public.users
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Users can insert own profile"
ON public.users
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
ON public.users
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- ---------------------------------------------------------------------------
-- sightings (community wildlife sightings — public read, owner write)
-- ---------------------------------------------------------------------------
ALTER TABLE public.sightings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view sightings" ON public.sightings;
DROP POLICY IF EXISTS "Users can create own sightings" ON public.sightings;
DROP POLICY IF EXISTS "Users can update own sightings" ON public.sightings;
DROP POLICY IF EXISTS "Users can delete own sightings" ON public.sightings;

CREATE POLICY "Anyone can view sightings"
ON public.sightings
FOR SELECT
USING (true);

CREATE POLICY "Users can create own sightings"
ON public.sightings
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sightings"
ON public.sightings
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own sightings"
ON public.sightings
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- wishlist (private per-user Big Five checklist)
-- ---------------------------------------------------------------------------
ALTER TABLE public.wishlist ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own wishlist" ON public.wishlist;
DROP POLICY IF EXISTS "Users can insert own wishlist items" ON public.wishlist;
DROP POLICY IF EXISTS "Users can update own wishlist items" ON public.wishlist;
DROP POLICY IF EXISTS "Users can delete own wishlist items" ON public.wishlist;

CREATE POLICY "Users can view own wishlist"
ON public.wishlist
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own wishlist items"
ON public.wishlist
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own wishlist items"
ON public.wishlist
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own wishlist items"
ON public.wishlist
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- marketplace (public browse, owner manages listings)
-- ---------------------------------------------------------------------------
ALTER TABLE public.marketplace ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view marketplace listings" ON public.marketplace;
DROP POLICY IF EXISTS "Users can create own marketplace listings" ON public.marketplace;
DROP POLICY IF EXISTS "Users can update own marketplace listings" ON public.marketplace;
DROP POLICY IF EXISTS "Users can delete own marketplace listings" ON public.marketplace;

CREATE POLICY "Anyone can view marketplace listings"
ON public.marketplace
FOR SELECT
USING (true);

CREATE POLICY "Users can create own marketplace listings"
ON public.marketplace
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own marketplace listings"
ON public.marketplace
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own marketplace listings"
ON public.marketplace
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- payments (strictly private — owner only)
-- ---------------------------------------------------------------------------
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own payments" ON public.payments;
DROP POLICY IF EXISTS "Users can create own payments" ON public.payments;

CREATE POLICY "Users can view own payments"
ON public.payments
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can create own payments"
ON public.payments
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- notifications (private inbox — owner read/update)
-- ---------------------------------------------------------------------------
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can insert own notifications" ON public.notifications;

CREATE POLICY "Users can view own notifications"
ON public.notifications
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
ON public.notifications
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Allow client-created notifications only when scoped to the signed-in user.
-- Server-side jobs should use the service_role key (bypasses RLS).
CREATE POLICY "Users can insert own notifications"
ON public.notifications
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);
