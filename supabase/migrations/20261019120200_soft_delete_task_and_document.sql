-- Soft delete for tasks and documents.
--
-- Verified against the live database as an impersonated user: a plain
--   UPDATE maintenance_tasks SET deleted_at = now() WHERE id = ...
-- fails with 42501 "new row violates row-level security policy", even though a
-- plain UPDATE of any other column works. The SELECT policy requires
-- `deleted_at IS NULL`, and the row Postgres would write back no longer
-- satisfies it. documents has the same policy shape. (This is the same problem
-- soft_delete_system / soft_delete_appliance already solve.)
--
-- So "Delete task" and "Delete document" in the app could not work through the
-- client. These SECURITY DEFINER functions do the update after an explicit
-- ownership check, like the existing ones, and pair with restore_task /
-- restore_document from 20261019120000.
--
-- anon is revoked by name: on Supabase new public functions get an explicit
-- anon grant, which `REVOKE ... FROM PUBLIC` alone does not remove.

CREATE OR REPLACE FUNCTION public.soft_delete_task(p_task_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  UPDATE maintenance_tasks
  SET deleted_at = NOW()
  WHERE id = p_task_id
    AND user_id = auth.uid()
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Task not found or access denied';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.soft_delete_document(p_document_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  UPDATE documents
  SET deleted_at = NOW()
  WHERE id = p_document_id
    AND user_id = auth.uid()
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Document not found or access denied';
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.soft_delete_task(UUID)     FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.soft_delete_document(UUID) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.soft_delete_task(UUID)     TO authenticated, service_role;
GRANT  EXECUTE ON FUNCTION public.soft_delete_document(UUID) TO authenticated, service_role;

-- ROLLBACK (not executed):
-- DROP FUNCTION IF EXISTS public.soft_delete_document(UUID);
-- DROP FUNCTION IF EXISTS public.soft_delete_task(UUID);
