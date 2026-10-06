-- Fixes §5 of 20261004170000_rls_hardening.sql, which did not work.
--
-- That section ran:
--   REVOKE EXECUTE ON FUNCTION ... FROM anon, authenticated;
--
-- PostgreSQL grants EXECUTE on every new function to PUBLIC by default, and
-- anon/authenticated inherit through PUBLIC. Revoking from the named roles left
-- the PUBLIC grant in place, so after that migration applied cleanly,
-- has_function_privilege('anon', ...) was still true for all nine functions and
-- the Supabase linter still flagged every one. The ACLs made it visible:
-- `=X/postgres`, where the empty grantee is PUBLIC.
--
-- Revoke from PUBLIC, then grant back explicitly.
--
-- Trigger invocation does not consult EXECUTE privilege, so removing it from
-- the four trigger bodies does not stop the triggers firing — it only closes
-- /rest/v1/rpc/<name>. Verified: inserting into auth.users still creates the
-- profile row via handle_new_user.

REVOKE EXECUTE ON FUNCTION public.handle_new_user()            FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.sync_phase_count()           FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.update_project_phase_count() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.delete_system_photo()        FROM PUBLIC;

-- Genuine RPCs: close the PUBLIC hole, restore what the app needs. Each
-- verifies ownership against auth.uid() internally, so `authenticated` is the
-- right audience; service_role is kept for Edge Functions.
REVOKE EXECUTE ON FUNCTION public.get_home_health_score(UUID)        FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_system_lifespan_overview(UUID) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_project_budget_summary(UUID)   FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.soft_delete_system(UUID)           FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.soft_delete_appliance(UUID)        FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.get_home_health_score(UUID)        TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_system_lifespan_overview(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_project_budget_summary(UUID)   TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.soft_delete_system(UUID)           TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.soft_delete_appliance(UUID)        TO authenticated, service_role;
