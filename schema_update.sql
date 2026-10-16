-- ====================================================================
-- ARJUN TRADERS - DATABASE MIGRATION SCRIPT (SAFE TO RUN ONCE)
-- Run this in Supabase Dashboard -> SQL Editor -> Run
-- ====================================================================

-- 1. ADD NEW COLUMNS TO ITEMS
ALTER TABLE items 
  ADD COLUMN IF NOT EXISTS free_bottles_per_case NUMERIC NOT NULL DEFAULT 0;

-- 2. ADD AUDIT & SETTINGS COLUMNS TO TRIP_LINES
ALTER TABLE trip_lines 
  ADD COLUMN IF NOT EXISTS free_per_case_used NUMERIC,
  ADD COLUMN IF NOT EXISTS free_adjusted INT,
  ADD COLUMN IF NOT EXISTS bottle_cost_used NUMERIC;

-- 3. CREATE SETTINGS TABLE (FOR EDITABLE BOTTLE COST & BUSINESS CONSTANTS)
CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. ENABLE ROW LEVEL SECURITY ON SETTINGS
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'settings' AND policyname = 'Allow members read settings'
  ) THEN
    CREATE POLICY "Allow members read settings" ON settings
      FOR SELECT TO authenticated
      USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid()));
  END IF;

  DROP POLICY IF EXISTS "Allow members write settings" ON settings;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'settings' AND policyname = 'Owner inserts settings'
  ) THEN
    CREATE POLICY "Owner inserts settings" ON settings
      FOR INSERT TO authenticated
      WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'settings' AND policyname = 'Owner updates settings'
  ) THEN
    CREATE POLICY "Owner updates settings" ON settings
      FOR UPDATE TO authenticated
      USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'))
      WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'settings' AND policyname = 'Owner deletes settings'
  ) THEN
    CREATE POLICY "Owner deletes settings" ON settings
      FOR DELETE TO authenticated
      USING (EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'owner'));
  END IF;
END $$;

GRANT ALL ON TABLE settings TO authenticated;

-- 5. INITIALIZE BOTTLE COST SETTING (Rs 10.40)
INSERT INTO settings (key, value)
VALUES ('bottle_cost', '10.40')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 6. SEED AUTOS (Auto 1, Auto 2, Auto 3)
INSERT INTO autos (name, default_driver)
SELECT a.name, a.default_driver
FROM (VALUES
  ('Auto 1', 'Driver 1'),
  ('Auto 2', 'Driver 2'),
  ('Auto 3', 'Driver 3')
) AS a(name, default_driver)
WHERE NOT EXISTS (
  SELECT 1 FROM autos WHERE autos.name = a.name
);

-- 7. SEED ITEMS FROM PAPER SHEET (Rate 0, editable in app)
INSERT INTO items (grp, name, rate, active, sort, free_bottles_per_case)
SELECT grp, name, rate, active, sort, free_bottles_per_case
FROM (VALUES
  -- 150ml: 1 free 1L bottle per case
  ('150ml', 'Raskik Mango', 0, true, 10, 1),
  ('150ml', 'Raskik Apple', 0, true, 20, 1),
  ('150ml', 'Raskik Mix', 0, true, 30, 1),
  ('150ml', 'Nimbu Pani', 0, true, 40, 1),
  ('150ml', 'Jeera-Up', 0, true, 50, 1),
  ('150ml', 'Gluco', 0, true, 60, 1),
  ('150ml', 'Berry 150', 0, true, 70, 1),
  ('150ml', 'Tetra', 0, true, 80, 1),
  ('150ml', 'Cup Nimbu', 0, true, 90, 1),
  ('150ml', 'Cup Gluco', 0, true, 100, 1),
  ('150ml', 'Salt', 0, true, 110, 1),
  ('150ml', 'R.Gold', 0, true, 120, 1),

  -- 200ml: 1 free 1L bottle per case
  ('200ml', 'Power Up', 0, true, 130, 1),
  ('200ml', 'Lemon', 0, true, 140, 1),
  ('200ml', 'Cola', 0, true, 150, 1),
  ('200ml', 'Orange', 0, true, 160, 1),
  ('200ml', 'Sun Mango', 0, true, 170, 1),
  ('200ml', 'Sun Orange', 0, true, 180, 1),
  ('200ml', 'Sun Mix', 0, true, 190, 1),
  ('200ml', 'V.Cola', 0, true, 200, 1),
  ('200ml', 'V.Lemon', 0, true, 210, 1),
  ('200ml', 'V.Orange', 0, true, 220, 1),

  -- 500/600ml: 2 free 1L bottles per case, EXCEPT Soda 500 which gets 1
  ('500/600ml', 'Berry 250', 0, true, 230, 2),
  ('500/600ml', 'Soda 500', 0, true, 240, 1), -- Soda 500 exception
  ('500/600ml', 'Power Up', 0, true, 250, 2),
  ('500/600ml', 'Lemon', 0, true, 260, 2),
  ('500/600ml', 'Cola', 0, true, 270, 2),
  ('500/600ml', 'Orange', 0, true, 280, 2),
  ('500/600ml', 'Jeera-Up', 0, true, 290, 2),
  ('500/600ml', 'Raskik 500', 0, true, 300, 2),
  ('500/600ml', 'Sun Mango', 0, true, 310, 2),
  ('500/600ml', 'Sun Orange', 0, true, 320, 2),

  -- 1 Lt: 0 free bottles
  ('1 Lt', 'Power Up', 0, true, 330, 0),
  ('1 Lt', 'Cola', 0, true, 340, 0),
  ('1 Lt', 'Lemon', 0, true, 350, 0),
  ('1 Lt', 'Orange', 0, true, 360, 0),

  -- Tins: 0 free bottles
  ('Tins', 'Gold Boost', 0, true, 370, 0),
  ('Tins', 'Power Up', 0, true, 380, 0),
  ('Tins', 'Cola', 0, true, 390, 0),
  ('Tins', 'Lemon', 0, true, 400, 0),
  ('Tins', 'Orange', 0, true, 410, 0),

  -- 2.5 Lt: 0 free bottles
  ('2.5 Lt', 'Power Up', 0, true, 420, 0),
  ('2.5 Lt', 'Lemon', 0, true, 430, 0),
  ('2.5 Lt', 'Cola', 0, true, 440, 0),
  ('2.5 Lt', 'Orange', 0, true, 450, 0),

  -- Water: 0 free bottles
  ('Water', '750ml', 0, true, 460, 0),
  ('Water', '1.5 Lt', 0, true, 470, 0),
  ('Water', 'Sure 250', 0, true, 480, 0),
  ('Water', 'Sure 500', 0, true, 490, 0),
  ('Water', 'Sure 1LT', 0, true, 500, 0),
  ('Water', 'Sure 2LT', 0, true, 510, 0),

  -- Gold
  ('Others', 'Gold', 0, true, 520, 0)
) AS v(grp, name, rate, active, sort, free_bottles_per_case)
WHERE NOT EXISTS (
  SELECT 1 FROM items WHERE items.name = v.name AND items.grp = v.grp
);

-- 8. PRE-FILL / UPDATE FREE BOTTLE RULES ON EXISTING ITEMS (Precedence: item > brand > group)
UPDATE items SET free_bottles_per_case = 1 WHERE grp IN ('150ml', '200ml');
UPDATE items SET free_bottles_per_case = 2 WHERE grp IN ('500/600ml', '500ml', '600ml');
UPDATE items SET free_bottles_per_case = 1 WHERE (name ILIKE '%Soda 500%' OR name ILIKE 'Soda 500ml') AND grp IN ('500/600ml', '500ml', '600ml');
UPDATE items SET free_bottles_per_case = 1 WHERE name ILIKE '%Vibe%';

-- Verification Query (Run this to verify settings and counts)
SELECT 'Settings' AS check_type, key, value FROM settings
UNION ALL
SELECT 'Autos Count' AS check_type, 'total', count(*)::text FROM autos
UNION ALL
SELECT 'Items Count' AS check_type, 'total', count(*)::text FROM items;
