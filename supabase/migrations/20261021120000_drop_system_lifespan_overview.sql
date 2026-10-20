-- Drop get_system_lifespan_overview(UUID).
--
-- It covered systems only and judged "aging" / "end of life" with different
-- thresholds than the kit. The app now computes lifespan itself, for systems
-- AND appliances together, from the kit's 75 / 90 / 100 percent bands
-- (LifespanReading). Verified before dropping: no app code, Edge Function,
-- test or other migration calls it (only the migrations that created and
-- revoked it, which run earlier).

DROP FUNCTION IF EXISTS public.get_system_lifespan_overview(UUID);

-- ROLLBACK (not executed): recreate it from
-- 20260307213811_add_get_system_lifespan_overview_rpc.sql, then re-apply the
-- grants/revokes from 20261005040000_revoke_function_execute_from_public.sql.
