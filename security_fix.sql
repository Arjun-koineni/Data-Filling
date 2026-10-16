-- ====================================================================
-- ARJUN TRADERS - SECURITY & ROLE-BASED ACCESS CONTROL (RBAC) FIX
-- Run this in Supabase Dashboard -> SQL Editor -> Run
--
-- Objective:
-- 1. Ensure `settings` table exists and initialize bottle_cost.
-- 2. Restrict Settings (1L promotional bottle cost) to Owner only (Staff read-only).
-- 3. Restrict Item Catalog & Predefined Rates to Owner only (Staff read-only).
-- 4. Restrict Vehicle fleet (autos) to Owner only (Staff read-only).
-- 5. Allow Staff to ADD shops on routes, but restrict Shop Renames/Deletes to Owner only.
-- 6. Allow Staff to RECORD dues/payments, but restrict Edit/Delete of ledger to Owner only.
-- 7. Allow Staff to create/fill daily trips, but restrict Trip Deletion to Owner only.
-- 8. Clean up old permissive "members only" policies that allowed ALL actions.
-- ====================================================================

-- --------------------------------------------------------------------
-- 0. ENSURE PREREQUISITE COLUMNS & SETTINGS TABLE EXIST
-- --------------------------------------------------------------------
ALTER TABLE items 
  ADD COLUMN IF NOT EXISTS free_bottles_per_case NUMERIC NOT NULL DEFAULT 0;

ALTER TABLE trip_lines 
  ADD COLUMN IF NOT EXISTS free_per_case_used NUMERIC,
  ADD COLUMN IF NOT EXISTS free_adjusted INT,
  ADD COLUMN IF NOT EXISTS bottle_cost_used NUMERIC;

CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

GRANT ALL ON TABLE settings TO authenticated;

INSERT INTO settings (key, value)
VALUES ('bottle_cost', '10.40')
ON CONFLICT (key) DO NOTHING;


-- --------------------------------------------------------------------
-- 1. SETTINGS TABLE POLICIES
-- --------------------------------------------------------------------
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "members only" ON settings;
DROP POLICY IF EXISTS "Allow members write settings" ON settings;
DROP POLICY IF EXISTS "Allow members read settings" ON settings;
DROP POLICY IF EXISTS "Owner inserts settings" ON settings;
DROP POLICY IF EXISTS "Owner updates settings" ON settings;
DROP POLICY IF EXISTS "Owner deletes settings" ON settings;

-- Read: All authenticated staff and owners can read settings
CREATE POLICY "Allow members read settings" ON settings
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid()));

-- Write: Owner only
CREATE POLICY "Owner inserts settings" ON settings
  FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));

CREATE POLICY "Owner updates settings" ON settings
  FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));

CREATE POLICY "Owner deletes settings" ON settings
  FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));


-- --------------------------------------------------------------------
-- 2. ITEMS TABLE (PREDEFINED RATES & CATALOG)
-- --------------------------------------------------------------------
ALTER TABLE items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "members only" ON items;
DROP POLICY IF EXISTS "Allow all members manage items" ON items;
DROP POLICY IF EXISTS "Allow members read items" ON items;
DROP POLICY IF EXISTS "Owner inserts items" ON items;
DROP POLICY IF EXISTS "Owner updates items" ON items;
DROP POLICY IF EXISTS "Owner deletes items" ON items;

-- Read: Staff & Owner can read items & prices
CREATE POLICY "Allow members read items" ON items
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid()));

-- Write: Owner only (Prevents staff from changing rates or adding unapproved items)
CREATE POLICY "Owner inserts items" ON items
  FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));

CREATE POLICY "Owner updates items" ON items
  FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));

CREATE POLICY "Owner deletes items" ON items
  FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));


-- --------------------------------------------------------------------
-- 3. AUTOS TABLE (VEHICLE FLEET)
-- --------------------------------------------------------------------
ALTER TABLE autos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "members only" ON autos;
DROP POLICY IF EXISTS "Allow all members manage autos" ON autos;
DROP POLICY IF EXISTS "Allow members read autos" ON autos;
DROP POLICY IF EXISTS "Owner inserts autos" ON autos;
DROP POLICY IF EXISTS "Owner updates autos" ON autos;
DROP POLICY IF EXISTS "Owner deletes autos" ON autos;

-- Read: Staff & Owner can see autos
CREATE POLICY "Allow members read autos" ON autos
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid()));

-- Write: Owner only
CREATE POLICY "Owner inserts autos" ON autos
  FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));

CREATE POLICY "Owner updates autos" ON autos
  FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));

CREATE POLICY "Owner deletes autos" ON autos
  FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));


-- --------------------------------------------------------------------
-- 4. SHOPS TABLE (CUSTOMERS)
-- --------------------------------------------------------------------
ALTER TABLE shops ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "members only" ON shops;
DROP POLICY IF EXISTS "Allow all members manage shops" ON shops;
DROP POLICY IF EXISTS "Allow members read shops" ON shops;
DROP POLICY IF EXISTS "Allow members insert shops" ON shops;
DROP POLICY IF EXISTS "Owner updates shops" ON shops;
DROP POLICY IF EXISTS "Owner deletes shops" ON shops;

-- Read: All members
CREATE POLICY "Allow members read shops" ON shops
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid()));

-- Insert: Staff can add a newly visited shop while on delivery route
CREATE POLICY "Allow members insert shops" ON shops
  FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid()));

-- Update (Rename): Owner only (Mistyped shops can only be renamed by Owner)
CREATE POLICY "Owner updates shops" ON shops
  FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));

-- Delete: Owner only
CREATE POLICY "Owner deletes shops" ON shops
  FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));


-- --------------------------------------------------------------------
-- 5. DUES TABLE (CREDIT & PAYMENTS LEDGER)
-- --------------------------------------------------------------------
ALTER TABLE dues ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "members only" ON dues;
DROP POLICY IF EXISTS "Allow all members manage dues" ON dues;
DROP POLICY IF EXISTS "Allow members read dues" ON dues;
DROP POLICY IF EXISTS "Allow members insert dues" ON dues;
DROP POLICY IF EXISTS "Owner updates dues" ON dues;
DROP POLICY IF EXISTS "Owner deletes dues" ON dues;

-- Read: All members
CREATE POLICY "Allow members read dues" ON dues
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid()));

-- Insert: Staff & Owner can record credit and received payments
CREATE POLICY "Allow members insert dues" ON dues
  FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid()));

-- Update/Delete: Owner only (Staff cannot erase or tamper with past debt/payment records)
CREATE POLICY "Owner updates dues" ON dues
  FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));

CREATE POLICY "Owner deletes dues" ON dues
  FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));


-- --------------------------------------------------------------------
-- 6. TRIPS & TRIP_LINES TABLES
-- --------------------------------------------------------------------
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_lines ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "members only" ON trips;
DROP POLICY IF EXISTS "Allow all members manage trips" ON trips;
DROP POLICY IF EXISTS "Allow members read trips" ON trips;
DROP POLICY IF EXISTS "Allow members insert trips" ON trips;
DROP POLICY IF EXISTS "Allow members update trips" ON trips;
DROP POLICY IF EXISTS "Owner deletes trips" ON trips;

CREATE POLICY "Allow members read trips" ON trips
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid()));

CREATE POLICY "Allow members insert trips" ON trips
  FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid()));

CREATE POLICY "Allow members update trips" ON trips
  FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid()));

-- Delete: Owner only
CREATE POLICY "Owner deletes trips" ON trips
  FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));

-- Trip Lines
DROP POLICY IF EXISTS "members only" ON trip_lines;
DROP POLICY IF EXISTS "Allow all members manage trip_lines" ON trip_lines;
DROP POLICY IF EXISTS "Allow members read trip_lines" ON trip_lines;
DROP POLICY IF EXISTS "Allow members insert trip_lines" ON trip_lines;
DROP POLICY IF EXISTS "Allow members update trip_lines" ON trip_lines;
DROP POLICY IF EXISTS "Owner deletes trip_lines" ON trip_lines;

CREATE POLICY "Allow members read trip_lines" ON trip_lines
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid()));

CREATE POLICY "Allow members insert trip_lines" ON trip_lines
  FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid()));

CREATE POLICY "Allow members update trip_lines" ON trip_lines
  FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid()));

CREATE POLICY "Owner deletes trip_lines" ON trip_lines
  FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));


-- --------------------------------------------------------------------
-- 7. AUDIT & VERIFICATION QUERY
-- --------------------------------------------------------------------
SELECT tablename, policyname, cmd, roles, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
