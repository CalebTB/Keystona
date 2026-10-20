-- Follow-up to 20261019120000_close_ui_data_gaps.sql.
--
-- That migration ran `REVOKE EXECUTE ... FROM PUBLIC` on restore_task,
-- restore_document and search_documents, but on Supabase every function created
-- in `public` also receives an EXPLICIT grant to anon (and authenticated and
-- service_role) from the project's default privileges. Revoking from PUBLIC
-- does not remove an explicit grant, so anon could still call all three through
-- /rest/v1/rpc/<name>. The data_gaps_test.sql assertion
-- `not has_function_privilege('anon', ...)` caught it.
--
-- (restore_* check ownership against auth.uid() inside, so an anonymous caller
-- could not have restored anything, and search_documents is SECURITY INVOKER so
-- RLS returned nothing. This closes the hole anyway: anon has no business here.)
--
-- Same lesson as 20261005040000_revoke_function_execute_from_public.sql; revoke
-- from anon by name as well as from PUBLIC.

REVOKE EXECUTE ON FUNCTION public.restore_task(UUID)                       FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.restore_document(UUID)                   FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.search_documents(UUID, TEXT, INTEGER)    FROM PUBLIC, anon;

-- ROLLBACK (not executed):
-- GRANT EXECUTE ON FUNCTION public.restore_task(UUID)                    TO anon;
-- GRANT EXECUTE ON FUNCTION public.restore_document(UUID)                TO anon;
-- GRANT EXECUTE ON FUNCTION public.search_documents(UUID, TEXT, INTEGER) TO anon;
