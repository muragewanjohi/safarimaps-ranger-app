-- SafariMap GameWarden Database Schema
-- Complete and updated schema for the SafariMap GameWarden application
-- Run this SQL in your Supabase SQL Editor

-- Drop existing tables if they exist (in reverse dependency order)
DROP TABLE IF EXISTS user_achievements CASCADE;
DROP TABLE IF EXISTS achievements CASCADE;
DROP TABLE IF EXISTS location_photos CASCADE;
DROP TABLE IF EXISTS reports CASCADE;
DROP TABLE IF EXISTS locations CASCADE;
DROP TABLE IF EXISTS incidents CASCADE;
DROP TABLE IF EXISTS ranger_parks CASCADE;
DROP TABLE IF EXISTS park_entries CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS parks CASCADE;

-- Drop existing types if they exist
DROP TYPE IF EXISTS entry_status CASCADE;
DROP TYPE IF EXISTS entry_type CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS location_category CASCADE;
DROP TYPE IF EXISTS incident_status CASCADE;
DROP TYPE IF EXISTS severity_level CASCADE;

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom types
CREATE TYPE severity_level AS ENUM ('Critical', 'High', 'Medium', 'Resolved');
CREATE TYPE incident_status AS ENUM ('Reported', 'In Progress', 'Resolved');
CREATE TYPE location_category AS ENUM ('Wildlife', 'Attraction', 'Hotel', 'Dining', 'Viewpoint');
CREATE TYPE user_role AS ENUM ('Ranger', 'Visitor', 'Admin', 'Park_Manager');
CREATE TYPE entry_type AS ENUM ('Entry', 'Exit');
CREATE TYPE entry_status AS ENUM ('Primary', 'Secondary', 'Emergency');

-- Parks table (must be created first as it's referenced by other tables)
CREATE TABLE parks (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  location TEXT,
  established DATE,
  area TEXT,
  size TEXT, -- Park size in km²
  coordinates TEXT,
  operating_hours TEXT,
  contact_info JSONB, -- Store phone, email, website as JSON
  admission_fees JSONB, -- Store different fee structures as JSON
  rules_and_regulations TEXT[],
  emergency_contacts JSONB,
  photos TEXT[], -- Array of photo URLs
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_coordinates CHECK (coordinates ~ '^-?\d+\.?\d*°\s*[NS],\s*-?\d+\.?\d*°\s*[EW]$'),
  CONSTRAINT valid_area CHECK (area ~ '^\d+.*km²$')
);

-- Park entries/exits table
CREATE TABLE park_entries (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  park_id UUID REFERENCES parks(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  entry_type entry_type NOT NULL DEFAULT 'Entry',
  status entry_status NOT NULL DEFAULT 'Secondary',
  coordinates TEXT NOT NULL,
  description TEXT,
  facilities TEXT[], -- e.g., ['Parking', 'Restrooms', 'Information Center']
  is_accessible BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_entry_coordinates CHECK (coordinates ~ '^-?\d+\.?\d*°\s*[NS],\s*-?\d+\.?\d*°\s*[EW]$')
);

-- Create partial unique indexes for primary entry/exit constraints
-- These ensure only one primary entry and one primary exit per park
CREATE UNIQUE INDEX unique_primary_entry_per_park 
ON park_entries (park_id) 
WHERE status = 'Primary' AND entry_type = 'Entry';

CREATE UNIQUE INDEX unique_primary_exit_per_park 
ON park_entries (park_id) 
WHERE status = 'Primary' AND entry_type = 'Exit';

-- Profiles table (extends Supabase auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name TEXT NOT NULL,
  role user_role NOT NULL DEFAULT 'Visitor',
  ranger_id TEXT UNIQUE, -- Only for rangers
  team TEXT, -- Only for rangers
  primary_park_id UUID REFERENCES parks(id), -- Primary park assignment
  avatar TEXT,
  phone TEXT,
  email TEXT,
  emergency_contact JSONB,
  join_date DATE DEFAULT CURRENT_DATE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_ranger_id CHECK (role != 'Ranger' OR ranger_id IS NOT NULL),
  CONSTRAINT valid_team CHECK (role != 'Ranger' OR team IS NOT NULL)
);

-- Ranger-Park assignments table (many-to-many relationship)
CREATE TABLE ranger_parks (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  ranger_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  park_id UUID REFERENCES parks(id) ON DELETE CASCADE NOT NULL,
  assigned_date DATE DEFAULT CURRENT_DATE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique ranger-park combinations
  UNIQUE(ranger_id, park_id)
);

-- Incidents table
CREATE TABLE incidents (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  park_id UUID REFERENCES parks(id) ON DELETE CASCADE NOT NULL,
  reported_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  type TEXT NOT NULL,
  description TEXT NOT NULL,
  location TEXT NOT NULL,
  coordinates TEXT,
  severity severity_level NOT NULL DEFAULT 'Medium',
  status incident_status NOT NULL DEFAULT 'Reported',
  reported_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_incident_coordinates CHECK (coordinates IS NULL OR coordinates ~ '^-?\d+\.?\d*°\s*[NS],\s*-?\d+\.?\d*°\s*[EW]$')
);

-- Locations table (for tracking wildlife, attractions, etc.)
CREATE TABLE locations (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  park_id UUID REFERENCES parks(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  category location_category NOT NULL,
  description TEXT,
  coordinates TEXT NOT NULL,
  is_verified BOOLEAN DEFAULT false,
  verified_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_location_coordinates CHECK (coordinates ~ '^-?\d+\.?\d*°\s*[NS],\s*-?\d+\.?\d*°\s*[EW]$')
);

-- Location photos table
CREATE TABLE location_photos (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  location_id UUID REFERENCES locations(id) ON DELETE CASCADE NOT NULL,
  photo_url TEXT NOT NULL,
  taken_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  taken_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_verified BOOLEAN DEFAULT false,
  verified_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reports table (for ranger reports)
CREATE TABLE reports (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  park_id UUID REFERENCES parks(id) ON DELETE CASCADE NOT NULL,
  reporter_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  location TEXT,
  coordinates TEXT,
  status TEXT DEFAULT 'Draft',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_report_coordinates CHECK (coordinates IS NULL OR coordinates ~ '^-?\d+\.?\d*°\s*[NS],\s*-?\d+\.?\d*°\s*[EW]$')
);

-- Achievements table
CREATE TABLE achievements (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  icon TEXT,
  points INTEGER DEFAULT 0,
  category TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User achievements table (many-to-many relationship)
CREATE TABLE user_achievements (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  achievement_id UUID REFERENCES achievements(id) ON DELETE CASCADE NOT NULL,
  earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique user-achievement combinations
  UNIQUE(user_id, achievement_id)
);

-- Create indexes for better performance
-- Park indexes
CREATE INDEX idx_parks_name ON parks(name);
CREATE INDEX idx_parks_location ON parks(location);

-- Park entries indexes
CREATE INDEX idx_park_entries_park_id ON park_entries(park_id);
CREATE INDEX idx_park_entries_type ON park_entries(entry_type);
CREATE INDEX idx_park_entries_status ON park_entries(status);

-- User role indexes
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_ranger_id ON profiles(ranger_id) WHERE ranger_id IS NOT NULL;
CREATE INDEX idx_profiles_is_active ON profiles(is_active);

-- Incident/location/report indexes
CREATE INDEX idx_incidents_reported_by ON incidents(reported_by);
CREATE INDEX idx_incidents_status ON incidents(status);
CREATE INDEX idx_incidents_severity ON incidents(severity);
CREATE INDEX idx_incidents_park_id ON incidents(park_id);
CREATE INDEX idx_incidents_reported_at ON incidents(reported_at);

CREATE INDEX idx_locations_park_id ON locations(park_id);
CREATE INDEX idx_locations_category ON locations(category);
CREATE INDEX idx_locations_is_verified ON locations(is_verified);

CREATE INDEX idx_reports_park_id ON reports(park_id);
CREATE INDEX idx_reports_reporter_id ON reports(reporter_id);
CREATE INDEX idx_reports_status ON reports(status);

-- Location photos indexes
CREATE INDEX idx_location_photos_location_id ON location_photos(location_id);
CREATE INDEX idx_location_photos_taken_by ON location_photos(taken_by) WHERE taken_by IS NOT NULL;
CREATE INDEX idx_location_photos_is_verified ON location_photos(is_verified);

-- User achievements indexes
CREATE INDEX idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX idx_user_achievements_achievement_id ON user_achievements(achievement_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_parks_updated_at BEFORE UPDATE ON parks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_park_entries_updated_at BEFORE UPDATE ON park_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_incidents_updated_at BEFORE UPDATE ON incidents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_locations_updated_at BEFORE UPDATE ON locations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE parks ENABLE ROW LEVEL SECURITY;
ALTER TABLE park_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE ranger_parks ENABLE ROW LEVEL SECURITY;
ALTER TABLE incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE location_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- RLS Policies for parks
CREATE POLICY "Anyone can view parks" ON parks FOR SELECT USING (true);
CREATE POLICY "Rangers can manage parks" ON parks FOR ALL USING (
  EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid() 
    AND p.role IN ('Ranger', 'Admin', 'Park_Manager')
  )
);

-- RLS Policies for park_entries
CREATE POLICY "Anyone can view park entries" ON park_entries FOR SELECT USING (true);
CREATE POLICY "Rangers can manage park entries" ON park_entries FOR ALL USING (
  EXISTS (
    SELECT 1 FROM profiles p
    JOIN ranger_parks rp ON rp.ranger_id = p.id
    WHERE p.id = auth.uid() 
    AND p.role = 'Ranger'
    AND rp.park_id = park_entries.park_id
  )
);

-- RLS Policies for profiles
CREATE POLICY "Users can view all profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- RLS Policies for ranger_parks
CREATE POLICY "Users can view ranger-park assignments" ON ranger_parks FOR SELECT USING (true);
CREATE POLICY "Rangers can manage their own assignments" ON ranger_parks FOR ALL USING (
  EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid() 
    AND p.role = 'Ranger'
    AND p.id = ranger_parks.ranger_id
  )
);

-- RLS Policies for incidents
CREATE POLICY "Users can view incidents" ON incidents FOR SELECT USING (true);
CREATE POLICY "Rangers can create incidents" ON incidents FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid() 
    AND p.role IN ('Ranger', 'Admin', 'Park_Manager')
  )
);
CREATE POLICY "Rangers can update incidents" ON incidents FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid() 
    AND p.role IN ('Ranger', 'Admin', 'Park_Manager')
  )
);

-- RLS Policies for locations
CREATE POLICY "Users can view locations" ON locations FOR SELECT USING (true);
CREATE POLICY "Rangers can manage locations" ON locations FOR ALL USING (
  EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid() 
    AND p.role IN ('Ranger', 'Admin', 'Park_Manager')
  )
);

-- RLS Policies for reports
CREATE POLICY "Users can view reports" ON reports FOR SELECT USING (true);
CREATE POLICY "Rangers can manage reports" ON reports FOR ALL USING (
  EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid() 
    AND p.role IN ('Ranger', 'Admin', 'Park_Manager')
  )
);

-- RLS Policies for location_photos
CREATE POLICY "Users can view location photos" ON location_photos FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM locations l
    JOIN parks p ON p.id = l.park_id
    WHERE l.id = location_photos.location_id 
    AND (
      -- Anyone can view photos from public parks
      true
      OR
      -- Or rangers assigned to the park
      EXISTS (
        SELECT 1 FROM profiles pr
        JOIN ranger_parks rp ON rp.ranger_id = pr.id
        WHERE pr.id = auth.uid() 
        AND pr.role = 'Ranger'
        AND rp.park_id = p.id
      )
    )
  )
);

CREATE POLICY "Users can create location photos" ON location_photos FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid() 
    AND p.role IN ('Ranger', 'Admin', 'Park_Manager')
  )
);

CREATE POLICY "Rangers can manage location photos" ON location_photos FOR ALL USING (
  EXISTS (
    SELECT 1 FROM profiles p
    JOIN locations l ON l.id = location_photos.location_id
    JOIN parks park ON park.id = l.park_id
    JOIN ranger_parks rp ON rp.park_id = park.id
    WHERE p.id = auth.uid() 
    AND p.role = 'Ranger'
    AND rp.ranger_id = p.id
  )
);

-- RLS Policies for achievements
CREATE POLICY "Users can view achievements" ON achievements FOR SELECT USING (true);
CREATE POLICY "Users can view user achievements" ON user_achievements FOR SELECT USING (true);

-- Insert sample data
INSERT INTO parks (name, description, location, established, area, size, coordinates, operating_hours, contact_info, admission_fees, rules_and_regulations, emergency_contacts) VALUES
('Masai Mara National Reserve', 'World-renowned safari destination in Kenya, famous for the Great Migration', 'Narok County, Kenya', '1961-01-01', '1,510 km²', '1,510 km²', '1.2921° S, 35.5739° E', '6:00 AM - 6:00 PM', '{"phone": "+254-20-2335863", "email": "info@maasaimara.com", "website": "https://www.maasaimara.com"}', '{"adult": 80, "child": 40, "student": 50}', ARRAY['No off-road driving', 'Stay in vehicle at all times', 'No feeding animals', 'Respect wildlife'], '{"ranger_emergency": "+254-700-000000", "medical": "+254-700-111111"}'),
('Amboseli National Park', 'Famous for its large elephant herds and views of Mount Kilimanjaro', 'Kajiado County, Kenya', '1974-01-01', '392 km²', '392 km²', '2.6531° S, 37.2506° E', '6:00 AM - 6:00 PM', '{"phone": "+254-45-622155", "email": "info@amboseli.com", "website": "https://www.amboseli.com"}', '{"adult": 60, "child": 30, "student": 40}', ARRAY['No off-road driving', 'Stay in vehicle at all times', 'No feeding animals', 'Respect wildlife'], '{"ranger_emergency": "+254-700-000001", "medical": "+254-700-111112"}'),
('Tsavo National Park', 'One of the largest national parks in Kenya, known for its red elephants', 'Taita-Taveta County, Kenya', '1948-01-01', '21,812 km²', '21,812 km²', '2.3333° S, 38.1167° E', '6:00 AM - 6:00 PM', '{"phone": "+254-43-30000", "email": "info@tsavo.com", "website": "https://www.tsavo.com"}', '{"adult": 70, "child": 35, "student": 45}', ARRAY['No off-road driving', 'Stay in vehicle at all times', 'No feeding animals', 'Respect wildlife'], '{"ranger_emergency": "+254-700-000002", "medical": "+254-700-111113"}');

-- Insert sample park entries
INSERT INTO park_entries (park_id, name, entry_type, status, coordinates, description, facilities) VALUES
-- Masai Mara entries
((SELECT id FROM parks WHERE name = 'Masai Mara National Reserve'), 'Sekenani Gate', 'Entry', 'Primary', '1.4000° S, 35.6000° E', 'Main entrance gate from Nairobi direction', ARRAY['Parking', 'Restrooms', 'Information Center', 'Souvenir Shop']),
((SELECT id FROM parks WHERE name = 'Masai Mara National Reserve'), 'Talek Gate', 'Exit', 'Primary', '1.2000° S, 35.5000° E', 'Main exit gate towards Narok', ARRAY['Parking', 'Restrooms', 'Information Center']),
((SELECT id FROM parks WHERE name = 'Masai Mara National Reserve'), 'Musiara Gate', 'Entry', 'Secondary', '1.3000° S, 35.5500° E', 'Secondary gate for lodge access', ARRAY['Parking', 'Restrooms']),

-- Amboseli entries
((SELECT id FROM parks WHERE name = 'Amboseli National Park'), 'Kimana Gate', 'Entry', 'Primary', '2.7000° S, 37.3000° E', 'Main entrance gate', ARRAY['Parking', 'Restrooms', 'Information Center', 'Souvenir Shop']),
((SELECT id FROM parks WHERE name = 'Amboseli National Park'), 'Iremito Gate', 'Exit', 'Primary', '2.6000° S, 37.2000° E', 'Main exit gate', ARRAY['Parking', 'Restrooms', 'Information Center']),

-- Tsavo entries
((SELECT id FROM parks WHERE name = 'Tsavo National Park'), 'Mtito Andei Gate', 'Entry', 'Primary', '2.4000° S, 38.1000° E', 'Main entrance gate', ARRAY['Parking', 'Restrooms', 'Information Center']),
((SELECT id FROM parks WHERE name = 'Tsavo National Park'), 'Voi Gate', 'Exit', 'Primary', '2.2000° S, 38.2000° E', 'Main exit gate', ARRAY['Parking', 'Restrooms', 'Information Center']);

-- Insert sample achievements
INSERT INTO achievements (name, description, icon, points, category) VALUES
('First Report', 'Submit your first incident report', '📝', 10, 'Reporting'),
('Wildlife Spotter', 'Spot and report 10 different wildlife species', '🦁', 50, 'Wildlife'),
('Park Explorer', 'Visit 5 different parks', '🗺️', 100, 'Exploration'),
('Incident Responder', 'Respond to 5 emergency incidents', '🚨', 75, 'Emergency'),
('Photo Contributor', 'Upload 20 location photos', '📸', 30, 'Documentation');

-- Create storage bucket for park photos
INSERT INTO storage.buckets (id, name, public) VALUES ('park-photos', 'park-photos', true);

-- Set up storage policies for park photos
CREATE POLICY "Anyone can view park photos" ON storage.objects FOR SELECT USING (bucket_id = 'park-photos');
CREATE POLICY "Authenticated users can upload park photos" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'park-photos' 
  AND auth.role() = 'authenticated'
);
CREATE POLICY "Users can delete their own park photos" ON storage.objects FOR DELETE USING (
  bucket_id = 'park-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Create function to handle new user profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  default_park_id UUID;
  user_name TEXT;
  user_email TEXT;
  ranger_id TEXT;
  team TEXT;
  user_role user_role;
  avatar_text TEXT;
BEGIN
  RAISE LOG 'Profile creation trigger fired for user: %', NEW.id;
  RAISE LOG 'User email: %', NEW.email;
  RAISE LOG 'User metadata: %', NEW.raw_user_meta_data;
  
  BEGIN
    -- Extract user information from metadata
    user_name := COALESCE(
      NEW.raw_user_meta_data->>'name',
      NEW.raw_user_meta_data->>'full_name',
      SPLIT_PART(NEW.email, '@', 1), -- Use email prefix as fallback
      'New User'
    );
    
    user_email := NEW.email;
    
    ranger_id := NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'ranger_id', '')), '');
    team := NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'team', '')), '');
    
    IF ranger_id IS NOT NULL AND ranger_id != '' THEN
      user_role := 'Ranger'::user_role;
    ELSE
      user_role := 'Visitor'::user_role;
    END IF;
    
    RAISE LOG 'Processed user data: name=%, role=%, ranger_id=%, team=%', user_name, user_role, ranger_id, team;
    
    SELECT id INTO default_park_id FROM parks WHERE name = 'Masai Mara National Reserve' LIMIT 1;
    
    IF default_park_id IS NULL THEN
      RAISE WARNING 'Default park "Masai Mara National Reserve" not found. Profile will be created without primary_park_id.';
    END IF;
    
    avatar_text := UPPER(SUBSTRING(COALESCE(user_name, 'NU'), 1, 2));
    
    INSERT INTO public.profiles (
      id, name, role, ranger_id, team, primary_park_id, avatar, email, join_date, is_active
    )
    VALUES (
      NEW.id,
      user_name,
      user_role,
      ranger_id,
      team,
      default_park_id, -- This might be NULL if default park not found
      avatar_text,
      user_email,
      CURRENT_DATE,
      true
    );
    
    RAISE LOG 'Profile created successfully for user: %', NEW.id;
    
    -- If user is a ranger, assign them to their primary park
    IF user_role = 'Ranger' AND default_park_id IS NOT NULL THEN
      INSERT INTO public.ranger_parks (ranger_id, park_id, assigned_date, is_active)
      VALUES (NEW.id, default_park_id, CURRENT_DATE, true);
      
      RAISE LOG 'Ranger assigned to park for user: %', NEW.id;
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
      -- Log the error but do NOT re-raise it, allowing the auth.users insert to complete
      RAISE LOG 'ERROR in trigger for user %: %', NEW.id, SQLERRM;
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO anon, authenticated;