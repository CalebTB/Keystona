-- ============================================================
-- Seed: By System view — edge case coverage
-- Cleanup marker: systems.serial_number = '__seed__'
-- Re-running is safe — deletes previous seed data first.
-- ============================================================

DO $$
DECLARE
  v_user_id     uuid;
  v_property_id uuid;

  s_hvac        uuid := gen_random_uuid();
  s_electrical  uuid := gen_random_uuid();
  s_plumbing    uuid := gen_random_uuid();
  s_roofing     uuid := gen_random_uuid();

  today         date := CURRENT_DATE;

BEGIN

  SELECT id INTO v_user_id FROM auth.users ORDER BY created_at LIMIT 1;
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'No user found'; END IF;

  SELECT id INTO v_property_id
    FROM properties WHERE user_id = v_user_id AND deleted_at IS NULL
    ORDER BY created_at LIMIT 1;
  IF v_property_id IS NULL THEN RAISE EXCEPTION 'No property found'; END IF;

  -- Wipe previous seed data (CASCADE removes linked tasks)
  DELETE FROM maintenance_tasks
    WHERE user_id = v_user_id
      AND linked_system_id IN (
        SELECT id FROM systems
        WHERE user_id = v_user_id AND serial_number = '__seed__'
      );

  DELETE FROM maintenance_tasks
    WHERE user_id = v_user_id
      AND linked_system_id IS NULL
      AND name IN (
        'Touch up exterior paint', 'Clean gutters', 'Seal driveway cracks',
        'Trim trees near power lines', 'Caulk around windows'
      );

  DELETE FROM systems
    WHERE user_id = v_user_id AND serial_number = '__seed__';

  -- ── Systems ──────────────────────────────────────────────────────────────

  -- 1. Carrier HVAC — many tasks (tests expand/overflow)
  INSERT INTO systems (id, property_id, user_id, category, system_type, name, status,
                       brand, model, serial_number, installation_date,
                       expected_lifespan_min, expected_lifespan_max,
                       location, estimated_replacement_cost)
  VALUES (s_hvac, v_property_id, v_user_id, 'hvac', 'furnace_gas',
          'Main Furnace', 'active',
          'Carrier', '58CVA070', '__seed__', '2018-03-15', 15, 20,
          'Basement', 4500.00);

  -- 2. Siemens Electrical — normal amount (4 tasks)
  INSERT INTO systems (id, property_id, user_id, category, system_type, name, status,
                       brand, serial_number, installation_date,
                       expected_lifespan_min, expected_lifespan_max, location)
  VALUES (s_electrical, v_property_id, v_user_id, 'electrical', 'panel',
          'Main Panel', 'active',
          'Siemens', '__seed__', '2015-06-01', 25, 40, 'Garage');

  -- 3. Plumbing — zero tasks (shows in All Clear)
  INSERT INTO systems (id, property_id, user_id, category, system_type, name, status,
                       serial_number, installation_date,
                       expected_lifespan_min, expected_lifespan_max, location)
  VALUES (s_plumbing, v_property_id, v_user_id, 'plumbing', 'water_heater_gas',
          'Water Heater', 'active',
          '__seed__', '2020-09-01', 8, 12, 'Utility Room');

  -- 4. Roofing — zero tasks (shows in All Clear)
  INSERT INTO systems (id, property_id, user_id, category, system_type, name, status,
                       serial_number, installation_date,
                       expected_lifespan_min, expected_lifespan_max)
  VALUES (s_roofing, v_property_id, v_user_id, 'roofing', 'asphalt_shingle',
          'Asphalt Roof', 'active',
          '__seed__', '2016-04-01', 20, 30);

  -- ── HVAC Tasks (10) ──────────────────────────────────────────────────────

  INSERT INTO maintenance_tasks
    (property_id, user_id, linked_system_id, name, category,
     due_date, recurrence, status, priority, task_origin)
  VALUES
    (v_property_id, v_user_id, s_hvac,
     'Replace air filter',           'HVAC', today - 45,  'monthly',   'overdue',   'high',     'custom'),
    (v_property_id, v_user_id, s_hvac,
     'Check refrigerant levels',     'HVAC', today - 8,   'annual',    'overdue',   'critical', 'custom'),
    (v_property_id, v_user_id, s_hvac,
     'Clean condenser coils',        'HVAC', today,        'annual',    'scheduled', 'high',     'custom'),
    (v_property_id, v_user_id, s_hvac,
     'Inspect ductwork for leaks',   'HVAC', today + 4,   'annual',    'scheduled', 'medium',   'custom'),
    (v_property_id, v_user_id, s_hvac,
     'Lubricate fan motor bearings', 'HVAC', today + 18,  'annual',    'scheduled', 'low',      'custom'),
    (v_property_id, v_user_id, s_hvac,
     'Schedule annual tune-up',      'HVAC', today + 75,  'annual',    'scheduled', 'medium',   'custom'),
    (v_property_id, v_user_id, s_hvac,
     'Change humidifier filter',     'HVAC', today - 30,  'monthly',   'completed', 'medium',   'custom'),
    (v_property_id, v_user_id, s_hvac,
     'Test CO detectors',            'HVAC', today - 90,  'quarterly', 'completed', 'high',     'custom'),
    (v_property_id, v_user_id, s_hvac,
     'Install smart thermostat',     'HVAC', today - 120, 'none',      'completed', 'medium',   'custom'),
    (v_property_id, v_user_id, s_hvac,
     'Deep clean evaporator coil',   'HVAC', today - 60,  'annual',    'skipped',   'low',      'custom');

  -- ── Electrical Tasks (4) ─────────────────────────────────────────────────

  INSERT INTO maintenance_tasks
    (property_id, user_id, linked_system_id, name, category,
     due_date, recurrence, status, priority, task_origin)
  VALUES
    (v_property_id, v_user_id, s_electrical,
     'Test GFCI outlets',            'Electrical', today - 14,  'annual',   'overdue',   'high',   'custom'),
    (v_property_id, v_user_id, s_electrical,
     'Inspect electrical panel',     'Electrical', today + 10,  'annual',   'scheduled', 'medium', 'custom'),
    (v_property_id, v_user_id, s_electrical,
     'Check smoke detector batteries','Electrical', today - 15,  'biannual', 'completed', 'high',   'custom'),
    (v_property_id, v_user_id, s_electrical,
     'Tighten outlet covers',        'Electrical', today + 120, 'annual',   'scheduled', 'low',    'custom');

  -- ── Uncategorized Tasks (5) ───────────────────────────────────────────────

  INSERT INTO maintenance_tasks
    (property_id, user_id, linked_system_id, name, category,
     due_date, recurrence, status, priority, task_origin)
  VALUES
    (v_property_id, v_user_id, NULL,
     'Touch up exterior paint',    'Exterior', today - 5,  'none',     'overdue',   'medium', 'custom'),
    (v_property_id, v_user_id, NULL,
     'Clean gutters',              'Exterior', today + 2,  'biannual', 'scheduled', 'high',   'custom'),
    (v_property_id, v_user_id, NULL,
     'Seal driveway cracks',       'Exterior', today + 30, 'annual',   'scheduled', 'low',    'custom'),
    (v_property_id, v_user_id, NULL,
     'Trim trees near power lines','Exterior', today + 55, 'annual',   'scheduled', 'medium', 'custom'),
    (v_property_id, v_user_id, NULL,
     'Caulk around windows',       'Exterior', today - 90, 'annual',   'completed', 'medium', 'custom');

  RAISE NOTICE 'Seed complete — user % / property %', v_user_id, v_property_id;

END $$;
