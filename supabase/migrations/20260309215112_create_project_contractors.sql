-- Project contractors join table
CREATE TABLE project_contractors (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id      UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  contact_id      UUID NOT NULL REFERENCES emergency_contacts(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES auth.users(id),
  role            TEXT,
  contract_amount NUMERIC,
  amount_paid     NUMERIC NOT NULL DEFAULT 0,
  rating          SMALLINT CHECK (rating BETWEEN 1 AND 5),
  review_notes    TEXT,
  linked_document_id UUID REFERENCES documents(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(project_id, contact_id)
);

ALTER TABLE project_contractors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own project contractors"
  ON project_contractors FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM projects p
      JOIN properties prop ON prop.id = p.property_id
      WHERE p.id = project_contractors.project_id
        AND prop.user_id = auth.uid()
        AND p.deleted_at IS NULL
    )
  );

CREATE INDEX idx_project_contractors_project_id ON project_contractors(project_id);

CREATE TRIGGER update_project_contractors_updated_at
  BEFORE UPDATE ON project_contractors
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
