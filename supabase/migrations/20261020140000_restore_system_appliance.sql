-- Undo for deleting a system or an appliance.
--
-- soft_delete_system / soft_delete_appliance exist, but nothing could bring a
-- deleted row back: RLS hides soft-deleted rows from SELECT and UPDATE, so a
-- plain UPDATE of deleted_at matches nothing. Same pattern as restore_task /
-- restore_document: SECURITY DEFINER with an explicit ownership check, and
-- anon revoked BY NAME (REVOKE FROM PUBLIC alone leaves Supabase's explicit
-- anon grant in place).

CREATE OR REPLACE FUNCTION public.restore_system(p_system_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  UPDATE systems
  SET deleted_at = NULL
  WHERE id = p_system_id
    AND user_id = auth.uid()
    AND deleted_at IS NOT NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'System not found or access denied';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.restore_appliance(p_appliance_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  UPDATE appliances
  SET deleted_at = NULL
  WHERE id = p_appliance_id
    AND user_id = auth.uid()
    AND deleted_at IS NOT NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Appliance not found or access denied';
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.restore_system(UUID)    FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.restore_appliance(UUID) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.restore_system(UUID)    TO authenticated, service_role;
GRANT  EXECUTE ON FUNCTION public.restore_appliance(UUID) TO authenticated, service_role;

-- ROLLBACK (not executed):
-- DROP FUNCTION IF EXISTS public.restore_appliance(UUID);
-- DROP FUNCTION IF EXISTS public.restore_system(UUID);
