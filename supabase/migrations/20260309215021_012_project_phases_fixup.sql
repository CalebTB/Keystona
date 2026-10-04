-- Add missing deleted_at column to project_phases
ALTER TABLE project_phases ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- Ensure RLS policy exists (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'project_phases' AND policyname = 'Users manage own project phases'
  ) THEN
    CREATE POLICY "Users manage own project phases"
      ON project_phases FOR ALL
      USING (
        EXISTS (
          SELECT 1 FROM projects p
          JOIN properties prop ON prop.id = p.property_id
          WHERE p.id = project_phases.project_id
            AND prop.user_id = auth.uid()
            AND p.deleted_at IS NULL
        )
      );
  END IF;
END $$;

-- Ensure updated_at trigger exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_project_phases_updated_at'
  ) THEN
    CREATE TRIGGER update_project_phases_updated_at
      BEFORE UPDATE ON project_phases
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- Ensure phase count trigger and function
CREATE OR REPLACE FUNCTION update_project_phase_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE projects
  SET phase_count = (
    SELECT COUNT(*) FROM project_phases
    WHERE project_id = COALESCE(NEW.project_id, OLD.project_id)
      AND deleted_at IS NULL
  )
  WHERE id = COALESCE(NEW.project_id, OLD.project_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'trg_update_phase_count'
  ) THEN
    CREATE TRIGGER trg_update_phase_count
      AFTER INSERT OR UPDATE OR DELETE ON project_phases
      FOR EACH ROW EXECUTE FUNCTION update_project_phase_count();
  END IF;
END $$;

-- Add any missing general_renovation templates
INSERT INTO project_phase_templates (project_type, name, description, sort_order)
SELECT * FROM (VALUES
  ('general_renovation', 'Planning',     'Define scope, budget, and timeline',     1),
  ('general_renovation', 'Preparation',  'Permits, material ordering, and site prep', 2),
  ('general_renovation', 'Construction', 'Primary construction work',              3),
  ('general_renovation', 'Finishing',    'Final details, paint, and cleanup',      4)
) AS new_rows(project_type, name, description, sort_order)
WHERE NOT EXISTS (
  SELECT 1 FROM project_phase_templates t 
  WHERE t.project_type = new_rows.project_type AND t.name = new_rows.name
);
