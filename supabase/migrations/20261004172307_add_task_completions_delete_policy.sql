-- task_completions had RLS enabled with SELECT/INSERT/UPDATE policies but no
-- DELETE policy. Postgres RLS denies any command with no matching permissive
-- policy, so every delete matched zero rows. PostgREST reports that as
-- success, so the undo-completion flow in task_detail_provider.dart appeared
-- to work while the completion row survived.
--
-- Consequences of the orphaned row: service history kept showing the entry,
-- repeat complete/undo cycles accumulated duplicates, and the task dropped
-- out of get_home_health_score entirely -- not counted as completed, and
-- excluded from the overdue count by its `t.id NOT IN (SELECT task_id FROM
-- task_completions ...)` clause.

CREATE POLICY "Users can delete own completions"
  ON public.task_completions FOR DELETE
  USING (user_id = auth.uid());
