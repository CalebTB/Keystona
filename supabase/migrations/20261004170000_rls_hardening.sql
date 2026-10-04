-- ============================================================
-- RLS / access-control hardening
--
-- Addresses findings confirmed against the live project on 2026-10-04,
-- cross-checked with `supabase db advisors --type security`.
-- All of these predate this migration; none were introduced by the
-- migration-recovery commit that surfaced them.
-- ============================================================


-- ── 1. project_phase_templates: RLS was OFF (Supabase linter: ERROR) ─────────
--
-- anon AND authenticated both held INSERT/UPDATE/DELETE/TRUNCATE on this
-- table with no RLS. The anon key ships inside the mobile binary, so this
-- was writable by an unauthenticated caller via /rest/v1.
--
-- The two sibling reference tables (maintenance_task_templates,
-- document_types) are already RLS-enabled with a read-only SELECT policy;
-- this table simply never got the same treatment.

ALTER TABLE public.project_phase_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view phase templates"
  ON public.project_phase_templates FOR SELECT
  USING (TRUE);

-- Defence in depth: RLS alone would still leave the grants in place.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE
  ON public.project_phase_templates FROM anon, authenticated;


-- ── 2. project_phases: weak policy OR'd with the strong one ─────────────────
--
-- The table carried two PERMISSIVE policies for ALL:
--   owner_all                       USING/CHECK: auth.uid() = user_id
--   Users manage own project phases USING: project->property ownership
--                                   CHECK: (absent)
--
-- Postgres ORs permissive policies, so `owner_all` defeated the stricter
-- one: setting user_id to your own id let you write a phase into another
-- user's project. The stricter policy also had no WITH CHECK, so Postgres
-- fell back to its USING clause for write validation.

DROP POLICY IF EXISTS "owner_all" ON public.project_phases;
DROP POLICY IF EXISTS "Users manage own project phases" ON public.project_phases;

CREATE POLICY "Users manage own project phases"
  ON public.project_phases FOR ALL
  USING (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.projects p
      WHERE p.id = project_phases.project_id
        AND p.user_id = auth.uid()
        AND p.deleted_at IS NULL
    )
  )
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.projects p
      WHERE p.id = project_phases.project_id
        AND p.user_id = auth.uid()
        AND p.deleted_at IS NULL
    )
  );


-- ── 3. task_completions: unvalidated task_id / property_id ──────────────────
--
-- INSERT only checked user_id = auth.uid(), leaving task_id and property_id
-- free. A user could attach a completion row to someone else's task, which
-- also feeds get_home_health_score — i.e. it could skew another account's
-- health score. UPDATE had no WITH CHECK at all.

-- The EXISTS below covers three things at once: the task belongs to the
-- caller, and the completion's property_id matches that task's property_id.
-- All three app insert sites already set property_id from the task's own
-- propertyId, so this matches real behaviour rather than constraining it.

DROP POLICY IF EXISTS "Users can insert own completions" ON public.task_completions;
CREATE POLICY "Users can insert own completions"
  ON public.task_completions FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.maintenance_tasks t
      WHERE t.id = task_completions.task_id
        AND t.user_id = auth.uid()
        AND t.property_id = task_completions.property_id
    )
    AND property_id IN (
      SELECT id FROM public.properties WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can update own completions" ON public.task_completions;
CREATE POLICY "Users can update own completions"
  ON public.task_completions FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.maintenance_tasks t
      WHERE t.id = task_completions.task_id
        AND t.user_id = auth.uid()
        AND t.property_id = task_completions.property_id
    )
    AND property_id IN (
      SELECT id FROM public.properties WHERE user_id = auth.uid()
    )
  );

-- The missing DELETE policy on task_completions was split out and APPLIED
-- separately as 20261004172307_add_task_completions_delete_policy.sql, since
-- it fixed a live functional bug (undo-completion silently doing nothing) and
-- was safe to ship on its own. It is intentionally not repeated here — this
-- file is still unapplied, and re-creating the policy would error.


-- ── 4. systems / appliances / maintenance_tasks: UPDATE could re-parent ─────
--
-- Their WITH CHECK was `user_id = auth.uid()` while the matching INSERT
-- policy also verified property ownership. A user could therefore UPDATE
-- one of their own rows to point at another user's property_id.
--
-- IMPORTANT: WITH CHECK must NOT include `deleted_at IS NULL`. The USING
-- clause has it, and if the check repeats it the row fails its own policy
-- the moment deleted_at is set — the documented 42501 soft-delete bug that
-- the soft_delete_system / soft_delete_appliance RPCs exist to work around.
-- Keep the check to ownership only so soft deletes keep working.

DROP POLICY IF EXISTS "Users can update own systems" ON public.systems;
CREATE POLICY "Users can update own systems"
  ON public.systems FOR UPDATE
  USING (user_id = auth.uid() AND deleted_at IS NULL)
  WITH CHECK (
    user_id = auth.uid()
    AND property_id IN (
      SELECT id FROM public.properties WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can update own appliances" ON public.appliances;
CREATE POLICY "Users can update own appliances"
  ON public.appliances FOR UPDATE
  USING (user_id = auth.uid() AND deleted_at IS NULL)
  WITH CHECK (
    user_id = auth.uid()
    AND property_id IN (
      SELECT id FROM public.properties WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can update own tasks" ON public.maintenance_tasks;
CREATE POLICY "Users can update own tasks"
  ON public.maintenance_tasks FOR UPDATE
  USING (user_id = auth.uid() AND deleted_at IS NULL)
  WITH CHECK (
    user_id = auth.uid()
    AND property_id IN (
      SELECT id FROM public.properties WHERE user_id = auth.uid()
    )
  );


-- ── 5. Trigger functions were callable as RPCs by anon ──────────────────────
--
-- These are trigger bodies, not API surface, but PostgREST exposes every
-- public function at /rest/v1/rpc/<name>. As SECURITY DEFINER they ran with
-- owner privileges. handle_new_user() in particular inserts into profiles.

REVOKE EXECUTE ON FUNCTION public.handle_new_user()             FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.sync_phase_count()            FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.update_project_phase_count()  FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.delete_system_photo()         FROM anon, authenticated;

-- The genuine RPCs stay callable by signed-in users only; each already
-- verifies ownership internally before reading data.
REVOKE EXECUTE ON FUNCTION public.get_home_health_score(UUID)           FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_system_lifespan_overview(UUID)    FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_project_budget_summary(UUID)      FROM anon;
REVOKE EXECUTE ON FUNCTION public.soft_delete_system(UUID)              FROM anon;
REVOKE EXECUTE ON FUNCTION public.soft_delete_appliance(UUID)           FROM anon;


-- ── 6. Mutable search_path on SECURITY DEFINER functions ────────────────────
--
-- A SECURITY DEFINER function with a mutable search_path can be hijacked by
-- a caller who creates a same-named object in an earlier schema. Migration
-- 20260227173223 fixed this for the functions that existed then; these four
-- were added afterwards and never got it.

ALTER FUNCTION public.sync_phase_count()                      SET search_path = public;
ALTER FUNCTION public.update_project_phase_count()             SET search_path = public;
ALTER FUNCTION public.get_project_budget_summary(UUID)         SET search_path = public;
ALTER FUNCTION public.get_system_lifespan_overview(UUID)       SET search_path = public;
