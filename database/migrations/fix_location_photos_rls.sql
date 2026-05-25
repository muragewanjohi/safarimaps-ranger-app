-- Fix location_photos RLS so rangers with location-create permission can attach photos.
-- Run in Supabase SQL Editor if add-location fails with:
-- "new row violates row-level security policy for table location_photos"

-- Ensure rangers/admins can insert photos for locations they can manage.
DROP POLICY IF EXISTS "Users can create location photos" ON location_photos;

CREATE POLICY "Users can create location photos"
ON location_photos
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.id = auth.uid()
      AND p.role IN ('Ranger', 'Admin', 'Park_Manager')
  )
  AND EXISTS (
    SELECT 1
    FROM locations l
    WHERE l.id = location_photos.location_id
  )
);
