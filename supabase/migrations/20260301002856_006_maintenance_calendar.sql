-- ============================================================
-- Migration 006: Maintenance Calendar
-- ============================================================

-- ---- MAINTENANCE TASK TEMPLATES ----

CREATE TABLE maintenance_task_templates (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  description     TEXT,
  instructions    TEXT,
  category        TEXT NOT NULL,
  season          TEXT,
  recurrence      recurrence_type NOT NULL DEFAULT 'annual',
  default_month   SMALLINT,
  difficulty      task_difficulty NOT NULL DEFAULT 'easy',
  diy_or_pro      diy_or_pro NOT NULL DEFAULT 'diy',
  priority        task_priority NOT NULL DEFAULT 'medium',
  estimated_minutes SMALLINT DEFAULT 30,
  tools_needed    JSONB DEFAULT '[]',
  supplies_needed JSONB DEFAULT '[]',
  climate_zones   SMALLINT[],
  system_category system_category,
  appliance_type  TEXT,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order      SMALLINT DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE maintenance_task_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view templates"
  ON maintenance_task_templates FOR SELECT
  USING (TRUE);


-- ---- MAINTENANCE TASKS ----

CREATE TABLE maintenance_tasks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id     UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  template_id     UUID REFERENCES maintenance_task_templates(id),
  task_origin     task_origin NOT NULL DEFAULT 'custom',
  name            TEXT NOT NULL,
  description     TEXT,
  instructions    TEXT,
  category        TEXT NOT NULL,
  linked_system_id    UUID REFERENCES systems(id) ON DELETE SET NULL,
  linked_appliance_id UUID REFERENCES appliances(id) ON DELETE SET NULL,
  due_date        DATE NOT NULL,
  recurrence      recurrence_type NOT NULL DEFAULT 'none',
  season          TEXT,
  climate_adjusted BOOLEAN DEFAULT FALSE,
  status          task_status NOT NULL DEFAULT 'scheduled',
  difficulty      task_difficulty NOT NULL DEFAULT 'easy',
  diy_or_pro      diy_or_pro NOT NULL DEFAULT 'diy',
  priority        task_priority NOT NULL DEFAULT 'medium',
  estimated_minutes SMALLINT,
  tools_needed    JSONB DEFAULT '[]',
  supplies_needed JSONB DEFAULT '[]',
  reminder_days_before SMALLINT DEFAULT 7,
  notifications_enabled BOOLEAN DEFAULT TRUE,
  reminded_7day   BOOLEAN DEFAULT FALSE,
  reminded_1day   BOOLEAN DEFAULT FALSE,
  skip_reason     TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE TRIGGER maintenance_tasks_updated_at
  BEFORE UPDATE ON maintenance_tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE maintenance_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own tasks"
  ON maintenance_tasks FOR SELECT
  USING (user_id = auth.uid() AND deleted_at IS NULL);

CREATE POLICY "Users can insert own tasks"
  ON maintenance_tasks FOR INSERT
  WITH CHECK (
    user_id = auth.uid() AND
    property_id IN (SELECT id FROM properties WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can update own tasks"
  ON maintenance_tasks FOR UPDATE
  USING (user_id = auth.uid() AND deleted_at IS NULL);

CREATE INDEX idx_tasks_property ON maintenance_tasks(property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_due ON maintenance_tasks(due_date, status) WHERE deleted_at IS NULL AND status NOT IN ('completed', 'skipped');
CREATE INDEX idx_tasks_status ON maintenance_tasks(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_system ON maintenance_tasks(linked_system_id) WHERE linked_system_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_tasks_overdue ON maintenance_tasks(due_date) WHERE status = 'scheduled' AND deleted_at IS NULL;


-- ---- TASK COMPLETIONS ----

CREATE TABLE task_completions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id         UUID NOT NULL REFERENCES maintenance_tasks(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  property_id     UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  completed_date  DATE NOT NULL DEFAULT CURRENT_DATE,
  completed_by    TEXT NOT NULL DEFAULT 'diy',
  contractor_name TEXT,
  contractor_company TEXT,
  contractor_phone TEXT,
  service_cost    NUMERIC(10,2),
  materials_cost  NUMERIC(10,2),
  time_spent_minutes SMALLINT,
  notes           TEXT,
  linked_document_ids UUID[] DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE task_completions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own completions"
  ON task_completions FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own completions"
  ON task_completions FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own completions"
  ON task_completions FOR UPDATE
  USING (user_id = auth.uid());

CREATE INDEX idx_completions_task ON task_completions(task_id);
CREATE INDEX idx_completions_property ON task_completions(property_id);
CREATE INDEX idx_completions_date ON task_completions(completed_date);


-- ---- COMPLETION PHOTOS ----

CREATE TABLE completion_photos (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  completion_id   UUID NOT NULL REFERENCES task_completions(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  file_path       TEXT NOT NULL,
  thumbnail_path  TEXT,
  caption         TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE completion_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own completion photos"
  ON completion_photos FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own completion photos"
  ON completion_photos FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE INDEX idx_completion_photos ON completion_photos(completion_id);
