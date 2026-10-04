-- ── Table: utility_shutoffs ──────────────────────────────────────────────────
CREATE TABLE utility_shutoffs (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id           UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id               UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  utility_type          TEXT NOT NULL CHECK (utility_type IN ('water', 'gas', 'electrical')),
  location_description  TEXT NOT NULL,
  valve_type            TEXT,
  turn_direction        TEXT,
  gas_company_phone     TEXT,
  main_breaker_location TEXT,
  main_breaker_amperage SMALLINT,
  circuit_directory     JSONB DEFAULT '[]',
  tools_required        JSONB DEFAULT '[]',
  special_instructions  TEXT,
  is_complete           BOOLEAN NOT NULL DEFAULT FALSE,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE utility_shutoffs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own shutoffs"    ON utility_shutoffs FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own shutoffs"  ON utility_shutoffs FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own shutoffs"  ON utility_shutoffs FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own shutoffs"  ON utility_shutoffs FOR DELETE USING (user_id = auth.uid());
CREATE INDEX idx_shutoffs_property ON utility_shutoffs(property_id);
CREATE TRIGGER set_updated_at_utility_shutoffs
  BEFORE UPDATE ON utility_shutoffs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ── Table: shutoff_photos ────────────────────────────────────────────────────
CREATE TABLE shutoff_photos (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shutoff_id        UUID NOT NULL REFERENCES utility_shutoffs(id) ON DELETE CASCADE,
  user_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  file_path         TEXT NOT NULL,
  thumbnail_path    TEXT,
  photo_type        TEXT NOT NULL DEFAULT 'location',
  caption           TEXT,
  file_size_bytes   INTEGER,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE shutoff_photos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own shutoff photos"   ON shutoff_photos FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own shutoff photos" ON shutoff_photos FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can delete own shutoff photos" ON shutoff_photos FOR DELETE USING (user_id = auth.uid());
CREATE INDEX idx_shutoff_photos_shutoff ON shutoff_photos(shutoff_id);

-- ── Table: emergency_contacts ────────────────────────────────────────────────
CREATE TABLE emergency_contacts (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id      UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id          UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  company_name     TEXT,
  category         contact_category NOT NULL,
  phone_primary    TEXT NOT NULL,
  phone_secondary  TEXT,
  email            TEXT,
  available_hours  TEXT,
  is_24x7          BOOLEAN NOT NULL DEFAULT FALSE,
  is_favorite      BOOLEAN NOT NULL DEFAULT FALSE,
  notes            TEXT,
  times_used       INTEGER NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own contacts"   ON emergency_contacts FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own contacts" ON emergency_contacts FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own contacts" ON emergency_contacts FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own contacts" ON emergency_contacts FOR DELETE USING (user_id = auth.uid());
CREATE INDEX idx_contacts_property  ON emergency_contacts(property_id);
CREATE INDEX idx_contacts_category  ON emergency_contacts(property_id, category);
CREATE INDEX idx_contacts_favorites ON emergency_contacts(property_id, is_favorite);
CREATE TRIGGER set_updated_at_emergency_contacts
  BEFORE UPDATE ON emergency_contacts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ── Table: insurance_info ────────────────────────────────────────────────────
CREATE TABLE insurance_info (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id         UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id             UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  policy_type         TEXT NOT NULL CHECK (policy_type IN ('homeowners','flood','earthquake','umbrella','home_warranty')),
  carrier             TEXT NOT NULL,
  policy_number       TEXT,
  coverage_amount     NUMERIC(12,2),
  deductible          NUMERIC(10,2),
  premium_annual      NUMERIC(10,2),
  agent_name          TEXT,
  agent_phone         TEXT,
  agent_email         TEXT,
  claims_phone        TEXT,
  effective_date      DATE,
  expiration_date     DATE,
  linked_document_id  UUID REFERENCES documents(id) ON DELETE SET NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at          TIMESTAMPTZ
);

ALTER TABLE insurance_info ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own insurance"   ON insurance_info FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own insurance" ON insurance_info FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own insurance" ON insurance_info FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own insurance" ON insurance_info FOR DELETE USING (user_id = auth.uid());
CREATE INDEX idx_insurance_property   ON insurance_info(property_id);
CREATE INDEX idx_insurance_expiration ON insurance_info(expiration_date) WHERE expiration_date IS NOT NULL;
CREATE TRIGGER set_updated_at_insurance_info
  BEFORE UPDATE ON insurance_info
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
