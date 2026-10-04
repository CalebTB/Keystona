-- Document link type enum
CREATE TYPE project_doc_link_type AS ENUM (
  'receipt', 'permit', 'contract', 'invoice', 'warranty', 'general'
);

-- Project documents join table
CREATE TABLE project_documents (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id  UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  linked_by   UUID NOT NULL REFERENCES auth.users(id),
  link_type   project_doc_link_type NOT NULL DEFAULT 'general',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(project_id, document_id)
);

ALTER TABLE project_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own project document links"
  ON project_documents FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM projects p
      JOIN properties prop ON prop.id = p.property_id
      WHERE p.id = project_documents.project_id
        AND prop.user_id = auth.uid()
        AND p.deleted_at IS NULL
    )
  );

CREATE INDEX idx_project_documents_project_id ON project_documents(project_id);
CREATE INDEX idx_project_documents_link_type ON project_documents(project_id, link_type);
