-- ── Projects ──────────────────────────────────────────────────────────────────

CREATE TYPE project_status AS ENUM (
  'planning',
  'in_progress',
  'on_hold',
  'completed',
  'cancelled'
);

CREATE TYPE project_type AS ENUM (
  'kitchen_remodel',
  'bathroom_remodel',
  'deck_build',
  'addition',
  'roofing',
  'flooring',
  'painting',
  'landscaping',
  'hvac_replacement',
  'other'
);

CREATE TABLE projects (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id           UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  name                  TEXT NOT NULL,
  description           TEXT,
  project_type          project_type NOT NULL DEFAULT 'other',
  status                project_status NOT NULL DEFAULT 'planning',

  -- Budget tracking.
  estimated_budget      NUMERIC(12, 2),
  actual_spent          NUMERIC(12, 2) NOT NULL DEFAULT 0,

  -- Date range.
  planned_start_date    DATE,
  planned_end_date      DATE,
  actual_start_date     DATE,
  actual_end_date       DATE,

  -- Cover photo (Supabase Storage path).
  cover_photo_path      TEXT,

  -- Phase count — denormalized from project_phases for list card performance.
  -- Updated by trigger when phases are added/removed (Phase 5.3).
  phase_count           SMALLINT NOT NULL DEFAULT 0,

  -- Contractor linking — populated by Phase 5.5.
  -- Stored as array of emergency_contacts.id values.
  contractor_ids        UUID[] NOT NULL DEFAULT '{}',

  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at            TIMESTAMPTZ
);

-- ── Indexes ───────────────────────────────────────────────────────────────────

CREATE INDEX idx_projects_property_id  ON projects(property_id);
CREATE INDEX idx_projects_user_id      ON projects(user_id);
CREATE INDEX idx_projects_status       ON projects(status);
CREATE INDEX idx_projects_updated_at   ON projects(updated_at DESC);
CREATE INDEX idx_projects_deleted_at   ON projects(deleted_at) WHERE deleted_at IS NULL;

-- ── updated_at trigger ────────────────────────────────────────────────────────

CREATE TRIGGER trg_projects_updated_at
  BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ── RLS ───────────────────────────────────────────────────────────────────────

ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own projects"
  ON projects
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
