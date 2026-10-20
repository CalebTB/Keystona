-- Sprint 3 (Home profile): data the kit shows that had nowhere to live.
-- ADDITIVE ONLY (new table, new defaulted columns). Rollback at the bottom.
--
--  1. item_service_log   "Log a repair or service" + the history timeline on a
--                        system / appliance (installed, purchased, service, repair)
--  2. systems.specifications   fuel, output, filter size (appliances already has it)
--  3. properties.has_basement  the "2 + basement" line on the home profile

-- ── 1. item_service_log ─────────────────────────────────────────────────────
-- A log of what happened to a system or appliance. Exactly one of system_id /
-- appliance_id is set. Hard-deleted (a log line the user removes is gone; the
-- app offers Undo by re-inserting it).

CREATE TABLE IF NOT EXISTS item_service_log (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id    UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id        UUID NOT NULL REFERENCES profiles(id)   ON DELETE CASCADE,
  system_id      UUID REFERENCES systems(id)    ON DELETE CASCADE,
  appliance_id   UUID REFERENCES appliances(id) ON DELETE CASCADE,

  kind           TEXT NOT NULL CHECK (kind IN ('installed', 'purchased', 'service', 'repair')),
  service_date   DATE NOT NULL,
  title          TEXT NOT NULL,
  provider       TEXT,
  cost           NUMERIC(10,2) CHECK (cost IS NULL OR cost >= 0),
  note           TEXT,
  under_warranty BOOLEAN NOT NULL DEFAULT FALSE,
  document_id    UUID REFERENCES documents(id) ON DELETE SET NULL,

  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT item_service_log_one_item CHECK ((system_id IS NULL) <> (appliance_id IS NULL))
);

CREATE TRIGGER item_service_log_updated_at
  BEFORE UPDATE ON item_service_log
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE item_service_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own item service log"
  ON item_service_log FOR SELECT
  USING (user_id = auth.uid());

-- The caller must own the property AND the item it is attached to.
CREATE POLICY "Users can insert own item service log"
  ON item_service_log FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND property_id IN (SELECT id FROM properties WHERE user_id = auth.uid())
    AND (
      (system_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM systems s
        WHERE s.id = item_service_log.system_id
          AND s.user_id = auth.uid()
          AND s.property_id = item_service_log.property_id))
      OR
      (appliance_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM appliances a
        WHERE a.id = item_service_log.appliance_id
          AND a.user_id = auth.uid()
          AND a.property_id = item_service_log.property_id))
    )
  );

CREATE POLICY "Users can update own item service log"
  ON item_service_log FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (
    user_id = auth.uid()
    AND property_id IN (SELECT id FROM properties WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can delete own item service log"
  ON item_service_log FOR DELETE
  USING (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_item_service_log_system
  ON item_service_log(system_id, service_date DESC) WHERE system_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_item_service_log_appliance
  ON item_service_log(appliance_id, service_date DESC) WHERE appliance_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_item_service_log_property
  ON item_service_log(property_id);

-- ── 2. systems.specifications ───────────────────────────────────────────────

ALTER TABLE systems
  ADD COLUMN IF NOT EXISTS specifications JSONB DEFAULT '{}'::jsonb;

-- ── 3. properties.has_basement ──────────────────────────────────────────────

ALTER TABLE properties
  ADD COLUMN IF NOT EXISTS has_basement BOOLEAN NOT NULL DEFAULT FALSE;

-- ============================================================================
-- ROLLBACK (not executed)
-- ============================================================================
-- ALTER TABLE properties DROP COLUMN IF EXISTS has_basement;
-- ALTER TABLE systems    DROP COLUMN IF EXISTS specifications;
-- DROP TABLE IF EXISTS item_service_log;
