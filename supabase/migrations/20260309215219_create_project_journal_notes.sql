-- Project journal notes table
CREATE TABLE project_journal_notes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id  UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  phase_id    UUID REFERENCES project_phases(id) ON DELETE SET NULL,
  user_id     UUID NOT NULL REFERENCES auth.users(id),
  title       TEXT,
  content     TEXT NOT NULL,
  note_date   DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at  TIMESTAMPTZ
);

ALTER TABLE project_journal_notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own project notes"
  ON project_journal_notes FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM projects p
      JOIN properties prop ON prop.id = p.property_id
      WHERE p.id = project_journal_notes.project_id
        AND prop.user_id = auth.uid()
        AND p.deleted_at IS NULL
    )
  );

CREATE INDEX idx_project_notes_project_id ON project_journal_notes(project_id);
CREATE INDEX idx_project_notes_date ON project_journal_notes(project_id, note_date DESC);

CREATE TRIGGER update_project_journal_notes_updated_at
  BEFORE UPDATE ON project_journal_notes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
