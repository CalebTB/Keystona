-- Project photo type enum
CREATE TYPE project_photo_type AS ENUM ('before', 'after', 'progress', 'inspiration', 'issue');

-- Project photos table
CREATE TABLE project_photos (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id      UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  phase_id        UUID REFERENCES project_phases(id) ON DELETE SET NULL,
  user_id         UUID NOT NULL REFERENCES auth.users(id),
  photo_type      project_photo_type NOT NULL DEFAULT 'progress',
  storage_path    TEXT NOT NULL,
  thumbnail_path  TEXT,
  caption         TEXT,
  room_tag        TEXT,
  pair_id         UUID,
  sort_order      SMALLINT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE project_photos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own project photos"
  ON project_photos FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM projects p
      JOIN properties prop ON prop.id = p.property_id
      WHERE p.id = project_photos.project_id
        AND prop.user_id = auth.uid()
        AND p.deleted_at IS NULL
    )
  );

CREATE INDEX idx_project_photos_project_id ON project_photos(project_id);
CREATE INDEX idx_project_photos_pair_id ON project_photos(pair_id) WHERE pair_id IS NOT NULL;
CREATE INDEX idx_project_photos_type ON project_photos(project_id, photo_type);

CREATE TRIGGER update_project_photos_updated_at
  BEFORE UPDATE ON project_photos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
