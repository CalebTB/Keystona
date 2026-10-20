-- ============================================================================
-- Close the data gaps found while rebuilding Docs (Sprint 1) and Tasks
-- (Sprint 2) to the Aurora kit. Each item below is something the new UI
-- already shows or accepts but could not store, so input was silently dropped
-- or an action silently did nothing.
--
-- ADDITIVE ONLY: new columns (nullable or defaulted), one new table, and three
-- new functions. Nothing is dropped, renamed or rewritten, so it is safe on a
-- database that already holds data. A rollback script is at the bottom.
--
--  1. maintenance_tasks   estimate, notes, "every N years", turned-off info, tags
--  2. task_completions    findings, "add to item history", the due date it met
--  3. task_skips          skipped occurrences (the history log never showed them)
--  4. restore_task()      Undo for deleting a task (RLS hides soft-deleted rows,
--                         so a plain UPDATE cannot bring one back)
--  5. restore_document()  same problem: Undo after "Delete document" matched
--                         zero rows and silently did nothing
--  6. documents.tags      tags were being stored inside metadata JSON
--  7. search_documents()  Premium full-text search; the app already calls it
--                         but it never existed, so search quietly fell back to
--                         name matching with no snippets
-- ============================================================================


-- ── 1. maintenance_tasks ────────────────────────────────────────────────────

ALTER TABLE maintenance_tasks
  -- Add task form "Estimate": was validated in the UI and then dropped.
  ADD COLUMN IF NOT EXISTS estimated_cost NUMERIC(10,2)
    CHECK (estimated_cost IS NULL OR estimated_cost >= 0),

  -- Task detail "Your notes".
  ADD COLUMN IF NOT EXISTS notes TEXT,

  -- "Every few years". recurrence_type has no interval, so a task that repeats
  -- every N years is recurrence = 'annual' plus this multiplier (NULL or 1 = every
  -- year). Only meaningful for annual tasks.
  ADD COLUMN IF NOT EXISTS recurrence_interval_years SMALLINT
    CHECK (recurrence_interval_years IS NULL OR recurrence_interval_years BETWEEN 2 AND 10),

  -- Turned-off reminders safety net: when and why a reminder was switched off.
  -- (Before this, "Off since" was guessed from updated_at.)
  ADD COLUMN IF NOT EXISTS notifications_off_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS notifications_off_reason TEXT,

  -- Why a reminder exists for this home: FREEZE, HUMID, STORMS, ...
  ADD COLUMN IF NOT EXISTS tags TEXT[] NOT NULL DEFAULT '{}';

ALTER TABLE maintenance_tasks
  ADD CONSTRAINT maintenance_tasks_interval_needs_annual
  CHECK (recurrence_interval_years IS NULL OR recurrence = 'annual');


-- ── 2. task_completions ─────────────────────────────────────────────────────

ALTER TABLE task_completions
  -- Log screen "What they found" chips.
  ADD COLUMN IF NOT EXISTS findings TEXT[] NOT NULL DEFAULT '{}',

  -- Log screen "Add to the furnace's history" switch.
  ADD COLUMN IF NOT EXISTS log_to_item_history BOOLEAN NOT NULL DEFAULT FALSE,

  -- The due date this completion answered. Lets history say "on time", "early"
  -- or "late" exactly, instead of guessing from the previous completion (which
  -- is wrong whenever a skip moved the schedule). NULL for older rows.
  ADD COLUMN IF NOT EXISTS due_date DATE;


-- ── 3. task_skips ───────────────────────────────────────────────────────────
-- An append-only log, like task_completions (no updated_at / deleted_at).

CREATE TABLE IF NOT EXISTS task_skips (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id      UUID NOT NULL REFERENCES maintenance_tasks(id) ON DELETE CASCADE,
  property_id  UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  skipped_on   DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date     DATE NOT NULL,     -- the occurrence that was skipped
  reason       TEXT,

  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE task_skips ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own task skips"
  ON task_skips FOR SELECT
  USING (user_id = auth.uid());

-- Same ownership proof as task_completions: the task and property must both
-- belong to the caller.
CREATE POLICY "Users can insert own task skips"
  ON task_skips FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM maintenance_tasks t
      WHERE t.id = task_skips.task_id
        AND t.user_id = auth.uid()
        AND t.property_id = task_skips.property_id
    )
    AND property_id IN (SELECT id FROM properties WHERE user_id = auth.uid())
  );

-- Needed so the Undo snackbar can take a skip back.
CREATE POLICY "Users can delete own task skips"
  ON task_skips FOR DELETE
  USING (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_task_skips_task     ON task_skips(task_id, skipped_on DESC);
CREATE INDEX IF NOT EXISTS idx_task_skips_property ON task_skips(property_id);


-- ── 4. restore_task() ───────────────────────────────────────────────────────
-- RLS hides soft-deleted rows from both SELECT and UPDATE, so the client cannot
-- clear deleted_at itself. Same pattern as soft_delete_system().

CREATE OR REPLACE FUNCTION public.restore_task(p_task_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  UPDATE maintenance_tasks
  SET deleted_at = NULL
  WHERE id = p_task_id
    AND user_id = auth.uid()
    AND deleted_at IS NOT NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Task not found or access denied';
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.restore_task(UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.restore_task(UUID) TO authenticated, service_role;


-- ── 5. restore_document() ───────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.restore_document(p_document_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  UPDATE documents
  SET deleted_at = NULL
  WHERE id = p_document_id
    AND user_id = auth.uid()
    AND deleted_at IS NOT NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Document not found or access denied';
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.restore_document(UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.restore_document(UUID) TO authenticated, service_role;


-- ── 6. documents.tags ───────────────────────────────────────────────────────

ALTER TABLE documents
  ADD COLUMN IF NOT EXISTS tags TEXT[] NOT NULL DEFAULT '{}';

-- Move tags the app already saved inside metadata->'tags' into the column.
UPDATE documents
SET tags = ARRAY(SELECT jsonb_array_elements_text(metadata -> 'tags'))
WHERE jsonb_typeof(metadata -> 'tags') = 'array'
  AND tags = '{}';

CREATE INDEX IF NOT EXISTS idx_documents_tags
  ON documents USING gin (tags) WHERE deleted_at IS NULL;

-- Tags are searchable. (Existing rows pick this up the next time they change.)
CREATE OR REPLACE FUNCTION public.update_document_search_vector()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $function$
BEGIN
  NEW.search_vector := to_tsvector('english',
    COALESCE(NEW.name, '') || ' ' ||
    COALESCE(NEW.ocr_text, '') || ' ' ||
    COALESCE(NEW.notes, '') || ' ' ||
    COALESCE(array_to_string(NEW.tags, ' '), '')
  );
  RETURN NEW;
END;
$function$;


-- ── 7. search_documents() ───────────────────────────────────────────────────
-- SECURITY INVOKER (the default): RLS on documents still applies, so a caller
-- can only ever search their own rows. Matches the full-text vector (name, OCR
-- text, notes, tags) or the name directly, and returns a snippet with the
-- matched terms wrapped in ** — the marker the app's SearchHighlight expects.

CREATE OR REPLACE FUNCTION public.search_documents(
  p_property_id UUID,
  p_query       TEXT,
  p_limit       INTEGER DEFAULT 20
)
RETURNS TABLE (
  id                  UUID,
  name                TEXT,
  category_id         UUID,
  document_type_id    UUID,
  file_path           TEXT,
  thumbnail_path      TEXT,
  file_size_bytes     INTEGER,
  mime_type           TEXT,
  page_count          SMALLINT,
  ocr_status          TEXT,
  expiration_date     DATE,
  linked_system_id    UUID,
  linked_appliance_id UUID,
  notes               TEXT,
  tags                TEXT[],
  created_at          TIMESTAMPTZ,
  updated_at          TIMESTAMPTZ,
  snippet             TEXT,
  rank                REAL
)
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  WITH q AS (
    SELECT websearch_to_tsquery('english', btrim(p_query)) AS tsq,
           lower(btrim(p_query))                           AS needle
  )
  SELECT
    d.id, d.name, d.category_id, d.document_type_id, d.file_path,
    d.thumbnail_path, d.file_size_bytes, d.mime_type, d.page_count,
    d.ocr_status, d.expiration_date, d.linked_system_id,
    d.linked_appliance_id, d.notes, d.tags, d.created_at, d.updated_at,
    CASE
      WHEN d.search_vector @@ q.tsq THEN ts_headline(
        'english',
        COALESCE(NULLIF(d.ocr_text, ''), NULLIF(d.notes, ''), d.name),
        q.tsq,
        'StartSel=**, StopSel=**, MaxWords=20, MinWords=8, MaxFragments=1'
      )
      ELSE NULL
    END AS snippet,
    ts_rank(d.search_vector, q.tsq) AS rank
  FROM documents d, q
  WHERE length(q.needle) > 0
    AND d.property_id = p_property_id
    AND d.deleted_at IS NULL
    AND (
      d.search_vector @@ q.tsq
      OR position(q.needle in lower(d.name)) > 0
    )
  ORDER BY rank DESC, d.created_at DESC
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 20), 1), 100);
$$;

REVOKE EXECUTE ON FUNCTION public.search_documents(UUID, TEXT, INTEGER) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.search_documents(UUID, TEXT, INTEGER) TO authenticated, service_role;


-- ============================================================================
-- ROLLBACK (not executed; run by hand to undo this migration)
-- ============================================================================
-- DROP FUNCTION IF EXISTS public.search_documents(UUID, TEXT, INTEGER);
-- DROP INDEX    IF EXISTS idx_documents_tags;
-- ALTER TABLE documents DROP COLUMN IF EXISTS tags;
-- -- restore the previous trigger body (name + ocr_text + notes only):
-- CREATE OR REPLACE FUNCTION public.update_document_search_vector() RETURNS trigger
--   LANGUAGE plpgsql SET search_path TO 'public' AS $f$ BEGIN
--   NEW.search_vector := to_tsvector('english', COALESCE(NEW.name,'') || ' ' ||
--     COALESCE(NEW.ocr_text,'') || ' ' || COALESCE(NEW.notes,'')); RETURN NEW; END; $f$;
-- DROP FUNCTION IF EXISTS public.restore_document(UUID);
-- DROP FUNCTION IF EXISTS public.restore_task(UUID);
-- DROP TABLE    IF EXISTS task_skips;
-- ALTER TABLE task_completions
--   DROP COLUMN IF EXISTS due_date,
--   DROP COLUMN IF EXISTS log_to_item_history,
--   DROP COLUMN IF EXISTS findings;
-- ALTER TABLE maintenance_tasks
--   DROP CONSTRAINT IF EXISTS maintenance_tasks_interval_needs_annual,
--   DROP COLUMN IF EXISTS tags,
--   DROP COLUMN IF EXISTS notifications_off_reason,
--   DROP COLUMN IF EXISTS notifications_off_at,
--   DROP COLUMN IF EXISTS recurrence_interval_years,
--   DROP COLUMN IF EXISTS notes,
--   DROP COLUMN IF EXISTS estimated_cost;
