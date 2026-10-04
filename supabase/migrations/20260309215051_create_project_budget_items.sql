-- Budget category enum
CREATE TYPE budget_category AS ENUM (
  'materials', 'labor', 'permits', 'fixtures', 'equipment_rental', 'design', 'other'
);

-- Project budget items table
CREATE TABLE project_budget_items (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id      UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  phase_id        UUID REFERENCES project_phases(id) ON DELETE SET NULL,
  user_id         UUID NOT NULL REFERENCES auth.users(id),
  name            TEXT NOT NULL,
  category        budget_category NOT NULL DEFAULT 'other',
  estimated_cost  NUMERIC,
  actual_cost     NUMERIC,
  vendor          TEXT,
  is_paid         BOOLEAN NOT NULL DEFAULT FALSE,
  receipt_document_id UUID REFERENCES documents(id) ON DELETE SET NULL,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at      TIMESTAMPTZ
);

ALTER TABLE project_budget_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own budget items"
  ON project_budget_items FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM projects p
      JOIN properties prop ON prop.id = p.property_id
      WHERE p.id = project_budget_items.project_id
        AND prop.user_id = auth.uid()
        AND p.deleted_at IS NULL
    )
  );

CREATE INDEX idx_budget_items_project_id ON project_budget_items(project_id);

CREATE TRIGGER update_project_budget_items_updated_at
  BEFORE UPDATE ON project_budget_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RPC: get_project_budget_summary
CREATE OR REPLACE FUNCTION get_project_budget_summary(p_project_id UUID)
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_property_id UUID;
  v_result JSON;
BEGIN
  -- Verify ownership via property
  SELECT p.property_id INTO v_property_id
  FROM projects p
  JOIN properties prop ON prop.id = p.property_id
  WHERE p.id = p_project_id
    AND prop.user_id = auth.uid()
    AND p.deleted_at IS NULL;

  IF v_property_id IS NULL THEN
    RAISE EXCEPTION 'Project not found or not authorized';
  END IF;

  SELECT json_build_object(
    'estimated_total', COALESCE(SUM(estimated_cost), 0),
    'actual_total',    COALESCE(SUM(actual_cost), 0),
    'remaining',       COALESCE(SUM(estimated_cost), 0) - COALESCE(SUM(actual_cost), 0),
    'category_breakdown', (
      SELECT json_agg(
        json_build_object(
          'category',  category,
          'estimated', COALESCE(SUM(estimated_cost), 0),
          'actual',    COALESCE(SUM(actual_cost), 0)
        )
      )
      FROM project_budget_items
      WHERE project_id = p_project_id
        AND deleted_at IS NULL
      GROUP BY category
      ORDER BY category
    )
  )
  INTO v_result
  FROM project_budget_items
  WHERE project_id = p_project_id
    AND deleted_at IS NULL;

  -- Also update actual_spent on the project
  UPDATE projects
  SET actual_spent = COALESCE((
    SELECT SUM(actual_cost) FROM project_budget_items
    WHERE project_id = p_project_id AND deleted_at IS NULL
  ), 0)
  WHERE id = p_project_id;

  RETURN COALESCE(v_result, '{"estimated_total":0,"actual_total":0,"remaining":0,"category_breakdown":[]}'::json);
END;
$$;
