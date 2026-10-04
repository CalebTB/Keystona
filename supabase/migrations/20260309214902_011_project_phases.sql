-- Enum for phase status (reuses same values as project_status)
DO $$ BEGIN
  CREATE TYPE phase_status AS ENUM ('planning','in_progress','on_hold','completed','cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Project phases table
CREATE TABLE public.project_phases (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id      UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  description     TEXT,
  status          phase_status NOT NULL DEFAULT 'planning',
  sort_order      SMALLINT NOT NULL DEFAULT 0,
  planned_start_date DATE,
  planned_end_date   DATE,
  actual_start_date  DATE,
  actual_end_date    DATE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.project_phases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner_all" ON public.project_phases
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_project_phases_project ON public.project_phases(project_id);
CREATE INDEX idx_project_phases_sort    ON public.project_phases(project_id, sort_order);

-- Trigger: keep updated_at fresh
CREATE TRIGGER set_updated_at_project_phases
  BEFORE UPDATE ON public.project_phases
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Trigger: maintain denormalized phase_count on projects
CREATE OR REPLACE FUNCTION public.sync_phase_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.projects
  SET phase_count = (
    SELECT COUNT(*) FROM public.project_phases
    WHERE project_id = COALESCE(NEW.project_id, OLD.project_id)
  )
  WHERE id = COALESCE(NEW.project_id, OLD.project_id);
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER sync_phase_count_trigger
  AFTER INSERT OR DELETE ON public.project_phases
  FOR EACH ROW EXECUTE FUNCTION public.sync_phase_count();

-- Phase templates (seed data: per project_type, standard phases)
CREATE TABLE public.project_phase_templates (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_type TEXT NOT NULL,
  name         TEXT NOT NULL,
  description  TEXT,
  sort_order   SMALLINT NOT NULL DEFAULT 0
);

-- No RLS needed -- templates are read-only reference data
INSERT INTO public.project_phase_templates (project_type, name, description, sort_order) VALUES
  ('kitchen_remodel', 'Planning & Design', 'Layout, measurements, material selection', 0),
  ('kitchen_remodel', 'Demo',              'Cabinet and flooring removal',               1),
  ('kitchen_remodel', 'Rough-In',          'Electrical, plumbing, HVAC updates',         2),
  ('kitchen_remodel', 'Installation',      'Cabinets, countertops, appliances',          3),
  ('kitchen_remodel', 'Finishing',         'Paint, fixtures, final touches',             4),
  ('bathroom_remodel', 'Planning & Design', 'Layout, tile selection, fixtures',           0),
  ('bathroom_remodel', 'Demo',              'Remove old fixtures and tile',               1),
  ('bathroom_remodel', 'Rough-In',          'Plumbing and electrical updates',            2),
  ('bathroom_remodel', 'Tile & Waterproof', 'Waterproofing, tile setting',               3),
  ('bathroom_remodel', 'Finishing',         'Fixtures, vanity, paint',                   4),
  ('deck_build', 'Planning & Permits', 'Design, HOA approval, permits',                  0),
  ('deck_build', 'Foundation',         'Posts, footings, beam installation',              1),
  ('deck_build', 'Framing',            'Joists and substructure',                        2),
  ('deck_build', 'Decking',            'Board installation',                              3),
  ('deck_build', 'Finishing',          'Railings, stairs, stain/seal',                   4),
  ('general_renovation', 'Planning',     'Define scope, budget, timeline',               0),
  ('general_renovation', 'Preparation',  'Permits, ordering materials, hiring',          1),
  ('general_renovation', 'Execution',    'Main construction work',                       2),
  ('general_renovation', 'Finishing',    'Final touches, cleanup, inspection',           3);
