-- ============================================================
-- Migration 005: Home Profile (Systems & Appliances)
-- ============================================================

-- ---- SYSTEMS ----

CREATE TABLE systems (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id     UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category        system_category NOT NULL,
  system_type     TEXT NOT NULL,
  name            TEXT NOT NULL,
  status          item_status NOT NULL DEFAULT 'active',
  brand           TEXT,
  model           TEXT,
  serial_number   TEXT,
  installation_date DATE,
  purchase_price  NUMERIC(10,2),
  installer       TEXT,
  location        TEXT,
  expected_lifespan_min SMALLINT,
  expected_lifespan_max SMALLINT,
  lifespan_override     SMALLINT,
  warranty_expiration   DATE,
  warranty_provider     TEXT,
  linked_warranty_doc_id UUID,
  estimated_replacement_cost NUMERIC(10,2),
  replaced_by_system_id     UUID REFERENCES systems(id),
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE TRIGGER systems_updated_at
  BEFORE UPDATE ON systems
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE systems ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own systems"
  ON systems FOR SELECT
  USING (user_id = auth.uid() AND deleted_at IS NULL);

CREATE POLICY "Users can insert own systems"
  ON systems FOR INSERT
  WITH CHECK (
    user_id = auth.uid() AND
    property_id IN (SELECT id FROM properties WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can update own systems"
  ON systems FOR UPDATE
  USING (user_id = auth.uid() AND deleted_at IS NULL);

CREATE INDEX idx_systems_property ON systems(property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_systems_category ON systems(property_id, category) WHERE deleted_at IS NULL;
CREATE INDEX idx_systems_warranty ON systems(warranty_expiration) WHERE warranty_expiration IS NOT NULL AND deleted_at IS NULL;


-- ---- APPLIANCES ----

CREATE TABLE appliances (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id     UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category        appliance_category NOT NULL,
  appliance_type  TEXT NOT NULL,
  name            TEXT NOT NULL,
  status          item_status NOT NULL DEFAULT 'active',
  brand           TEXT,
  model           TEXT,
  serial_number   TEXT,
  color           TEXT,
  purchase_date   DATE,
  purchase_price  NUMERIC(10,2),
  retailer        TEXT,
  location        TEXT,
  expected_lifespan_min SMALLINT,
  expected_lifespan_max SMALLINT,
  lifespan_override     SMALLINT,
  warranty_expiration   DATE,
  warranty_provider     TEXT,
  linked_warranty_doc_id UUID,
  specifications  JSONB DEFAULT '{}',
  estimated_replacement_cost NUMERIC(10,2),
  replaced_by_appliance_id  UUID REFERENCES appliances(id),
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE TRIGGER appliances_updated_at
  BEFORE UPDATE ON appliances
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE appliances ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own appliances"
  ON appliances FOR SELECT
  USING (user_id = auth.uid() AND deleted_at IS NULL);

CREATE POLICY "Users can insert own appliances"
  ON appliances FOR INSERT
  WITH CHECK (
    user_id = auth.uid() AND
    property_id IN (SELECT id FROM properties WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can update own appliances"
  ON appliances FOR UPDATE
  USING (user_id = auth.uid() AND deleted_at IS NULL);

CREATE INDEX idx_appliances_property ON appliances(property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_appliances_category ON appliances(property_id, category) WHERE deleted_at IS NULL;
CREATE INDEX idx_appliances_warranty ON appliances(warranty_expiration) WHERE warranty_expiration IS NOT NULL AND deleted_at IS NULL;


-- ---- PHOTOS (shared for systems & appliances) ----

CREATE TABLE item_photos (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  system_id       UUID REFERENCES systems(id) ON DELETE CASCADE,
  appliance_id    UUID REFERENCES appliances(id) ON DELETE CASCADE,
  file_path       TEXT NOT NULL,
  thumbnail_path  TEXT,
  photo_type      TEXT NOT NULL DEFAULT 'overview',
  caption         TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT photo_has_one_parent CHECK (
    (system_id IS NOT NULL AND appliance_id IS NULL) OR
    (system_id IS NULL AND appliance_id IS NOT NULL)
  )
);

ALTER TABLE item_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own item photos"
  ON item_photos FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own item photos"
  ON item_photos FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own item photos"
  ON item_photos FOR DELETE
  USING (user_id = auth.uid());

CREATE INDEX idx_item_photos_system ON item_photos(system_id) WHERE system_id IS NOT NULL;
CREATE INDEX idx_item_photos_appliance ON item_photos(appliance_id) WHERE appliance_id IS NOT NULL;


-- ---- Add FK from documents to systems/appliances ----

ALTER TABLE documents
  ADD CONSTRAINT fk_documents_system FOREIGN KEY (linked_system_id) REFERENCES systems(id) ON DELETE SET NULL;

ALTER TABLE documents
  ADD CONSTRAINT fk_documents_appliance FOREIGN KEY (linked_appliance_id) REFERENCES appliances(id) ON DELETE SET NULL;
