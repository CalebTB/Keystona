-- Tests for 20261019120000_close_ui_data_gaps.sql, 20261019120100_revoke_anon_on_new_functions.sql
-- and 20261019120200_soft_delete_task_and_document.sql
--
-- Same harness and safety model as rls_boundaries_test.sql: the whole script
-- runs inside BEGIN ... ROLLBACK against two throwaway users, so it is safe to
-- run against any database. Silence is not success: the last SELECT prints
-- PASS, and any failed assertion aborts with `FAIL: <what>`.
--
--   psql "$SUPABASE_DB_URL" -f supabase/tests/data_gaps_test.sql
--   (or run through the Supabase MCP execute_sql)

begin;

create function pg_temp.assert_eq(actual bigint, expected bigint, what text)
returns void language plpgsql as $$
begin
  if actual is distinct from expected then
    raise exception 'FAIL: % — expected %, got %', what, expected, actual;
  end if;
end $$;

create function pg_temp.assert_true(actual boolean, what text)
returns void language plpgsql as $$
begin
  if actual is distinct from true then
    raise exception 'FAIL: % — expected true, got %', what, actual;
  end if;
end $$;

-- The statement must raise. (A FAIL raised inside the block is re-raised.)
create function pg_temp.assert_raises(stmt text, what text)
returns void language plpgsql as $$
begin
  execute stmt;
  raise exception 'FAIL: % — expected an error but the statement succeeded', what;
exception when others then
  if sqlerrm like 'FAIL:%' then raise; end if;
  return;
end $$;

-- ── Fixtures ────────────────────────────────────────────────────────────────
--   user A     11111111-1111-4111-8111-111111111111
--   user B     22222222-2222-4222-8222-222222222222
--   property A 1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa
--   property B 2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb
--   task A     1a1a1a1a-1111-4111-8111-cccccccccccc
--   task B     2b2b2b2b-2222-4222-8222-dddddddddddd

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
)
select '00000000-0000-0000-0000-000000000000', v.id, 'authenticated',
       'authenticated', v.label || '@gaps-test.invalid',
       crypt('not-a-real-password', gen_salt('bf')),
       now(), now(), now(), '', '', '', ''
from (values
  ('user_a', '11111111-1111-4111-8111-111111111111'::uuid),
  ('user_b', '22222222-2222-4222-8222-222222222222'::uuid)
) as v(label, id);

insert into properties (id, user_id, address_line1, city, state, zip_code)
values
  ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', '1 A St', 'Austin', 'TX', '78704'),
  ('2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222222', '2 B St', 'Austin', 'TX', '78704');

insert into maintenance_tasks (id, property_id, user_id, name, category, due_date)
values
  ('1a1a1a1a-1111-4111-8111-cccccccccccc', '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'A task', 'hvac', current_date),
  ('2b2b2b2b-2222-4222-8222-dddddddddddd', '2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222222', 'B task', 'hvac', current_date);

-- Documents need a category: reuse a system one.
insert into documents (id, property_id, user_id, name, category_id, file_path, ocr_text, tags)
select v.id, v.pid, v.uid, v.nm,
       (select id from document_categories order by created_at limit 1),
       v.path, v.ocr, v.tags
from (values
  ('1a1a1a1a-1111-4111-8111-111111111aaa'::uuid, '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa'::uuid, '11111111-1111-4111-8111-111111111111'::uuid,
   'Furnace warranty', 'a/w.pdf', 'This warranty covers the heat exchanger for ten years', array['hvac','2021 install']),
  ('1a1a1a1a-1111-4111-8111-111111112bbb'::uuid, '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa'::uuid, '11111111-1111-4111-8111-111111111111'::uuid,
   'Roof receipt', 'a/r.pdf', null::text, array['roofing']),
  ('2b2b2b2b-2222-4222-8222-222222222ccc'::uuid, '2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb'::uuid, '22222222-2222-4222-8222-222222222222'::uuid,
   'Furnace manual', 'b/m.pdf', 'furnace furnace furnace', array['hvac'])
) as v(id, pid, uid, nm, path, ocr, tags)
where exists (select 1 from document_categories);

-- ── Constraints on the new maintenance_tasks columns (as the table owner) ───

select pg_temp.assert_raises(
  $$update maintenance_tasks set estimated_cost = -1 where id = '1a1a1a1a-1111-4111-8111-cccccccccccc'$$,
  'a negative estimate is rejected');
select pg_temp.assert_raises(
  $$update maintenance_tasks set recurrence = 'annual', recurrence_interval_years = 1 where id = '1a1a1a1a-1111-4111-8111-cccccccccccc'$$,
  'every 1 year is not an interval (use plain annual)');
select pg_temp.assert_raises(
  $$update maintenance_tasks set recurrence = 'annual', recurrence_interval_years = 11 where id = '1a1a1a1a-1111-4111-8111-cccccccccccc'$$,
  'more than 10 years is rejected');
select pg_temp.assert_raises(
  $$update maintenance_tasks set recurrence = 'monthly', recurrence_interval_years = 3 where id = '1a1a1a1a-1111-4111-8111-cccccccccccc'$$,
  'an N-year interval only makes sense for annual tasks');

-- A valid value round-trips.
update maintenance_tasks
set estimated_cost = 25.50, notes = 'Filter is in the garage',
    recurrence = 'annual', recurrence_interval_years = 3,
    notifications_off_at = now(), notifications_off_reason = 'No sprinkler system',
    tags = array['FREEZE']
where id = '1a1a1a1a-1111-4111-8111-cccccccccccc';
select pg_temp.assert_eq(
  (select count(*) from maintenance_tasks
   where id = '1a1a1a1a-1111-4111-8111-cccccccccccc'
     and estimated_cost = 25.50 and recurrence_interval_years = 3
     and tags = array['FREEZE']), 1,
  'new maintenance_tasks columns store and read back');

-- New completion columns have safe defaults and accept values.
insert into task_completions (task_id, user_id, property_id, findings, log_to_item_history, due_date)
values ('1a1a1a1a-1111-4111-8111-cccccccccccc', '11111111-1111-4111-8111-111111111111',
        '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', array['rust'], true, current_date - 3);
insert into task_completions (task_id, user_id, property_id)
values ('1a1a1a1a-1111-4111-8111-cccccccccccc', '11111111-1111-4111-8111-111111111111',
        '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa');
select pg_temp.assert_eq(
  (select count(*) from task_completions
   where task_id = '1a1a1a1a-1111-4111-8111-cccccccccccc'
     and findings = '{}' and log_to_item_history = false and due_date is null), 1,
  'a completion with no new fields gets safe defaults');

-- ── Function privileges ─────────────────────────────────────────────────────

select pg_temp.assert_true(not has_function_privilege('anon', 'public.restore_task(uuid)', 'execute'),
  'anon cannot call restore_task');
select pg_temp.assert_true(not has_function_privilege('anon', 'public.restore_document(uuid)', 'execute'),
  'anon cannot call restore_document');
select pg_temp.assert_true(not has_function_privilege('anon', 'public.search_documents(uuid,text,integer)', 'execute'),
  'anon cannot call search_documents');
select pg_temp.assert_true(not has_function_privilege('anon', 'public.soft_delete_task(uuid)', 'execute'),
  'anon cannot call soft_delete_task');
select pg_temp.assert_true(not has_function_privilege('anon', 'public.soft_delete_document(uuid)', 'execute'),
  'anon cannot call soft_delete_document');
select pg_temp.assert_true(has_function_privilege('authenticated', 'public.restore_task(uuid)', 'execute'),
  'authenticated can call restore_task');
select pg_temp.assert_true(has_function_privilege('authenticated', 'public.soft_delete_task(uuid)', 'execute'),
  'authenticated can call soft_delete_task');

-- ── As user A ───────────────────────────────────────────────────────────────

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}';

-- restore_task: delete, confirm it is hidden, restore, confirm it is back.
-- A plain-UPDATE soft delete is blocked by RLS (the SELECT policy hides the
-- row it would write back). That is why soft_delete_task exists.
select pg_temp.assert_raises(
  $$update maintenance_tasks set deleted_at = now() where id = '1a1a1a1a-1111-4111-8111-cccccccccccc'$$,
  'a plain UPDATE cannot soft-delete a task (42501) — use soft_delete_task');
select pg_temp.assert_raises($$select soft_delete_task('2b2b2b2b-2222-4222-8222-dddddddddddd')$$,
  'A cannot soft-delete B''s task');
select soft_delete_task('1a1a1a1a-1111-4111-8111-cccccccccccc');
select pg_temp.assert_eq((select count(*) from maintenance_tasks where id = '1a1a1a1a-1111-4111-8111-cccccccccccc'), 0,
  'a deleted task is hidden from its owner');
select pg_temp.assert_raises($$select soft_delete_task('1a1a1a1a-1111-4111-8111-cccccccccccc')$$,
  'deleting an already-deleted task raises');
-- The bug being fixed: a plain UPDATE cannot bring it back (RLS hides the row).
update maintenance_tasks set deleted_at = null where id = '1a1a1a1a-1111-4111-8111-cccccccccccc';
select pg_temp.assert_eq((select count(*) from maintenance_tasks where id = '1a1a1a1a-1111-4111-8111-cccccccccccc'), 0,
  'a plain UPDATE still cannot restore a deleted task (why restore_task exists)');
select restore_task('1a1a1a1a-1111-4111-8111-cccccccccccc');
select pg_temp.assert_eq((select count(*) from maintenance_tasks where id = '1a1a1a1a-1111-4111-8111-cccccccccccc'), 1,
  'restore_task brings the task back');
select pg_temp.assert_raises($$select restore_task('1a1a1a1a-1111-4111-8111-cccccccccccc')$$,
  'restoring a task that is not deleted raises');
select pg_temp.assert_raises($$select restore_task('2b2b2b2b-2222-4222-8222-dddddddddddd')$$,
  'A cannot restore B''s task');

-- restore_document: same pattern.
select pg_temp.assert_raises(
  $$update documents set deleted_at = now() where id = '1a1a1a1a-1111-4111-8111-111111112bbb'$$,
  'a plain UPDATE cannot soft-delete a document (42501) — use soft_delete_document');
select pg_temp.assert_raises($$select soft_delete_document('2b2b2b2b-2222-4222-8222-222222222ccc')$$,
  'A cannot soft-delete B''s document');
select soft_delete_document('1a1a1a1a-1111-4111-8111-111111112bbb');
select pg_temp.assert_eq((select count(*) from documents where id = '1a1a1a1a-1111-4111-8111-111111112bbb'), 0,
  'a deleted document is hidden from its owner');
select restore_document('1a1a1a1a-1111-4111-8111-111111112bbb');
select pg_temp.assert_eq((select count(*) from documents where id = '1a1a1a1a-1111-4111-8111-111111112bbb'), 1,
  'restore_document brings the document back');
select pg_temp.assert_raises($$select restore_document('2b2b2b2b-2222-4222-8222-222222222ccc')$$,
  'A cannot restore B''s document (or probe that it exists)');

-- task_skips: own rows only.
insert into task_skips (task_id, property_id, user_id, due_date, reason)
values ('1a1a1a1a-1111-4111-8111-cccccccccccc', '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa',
        '11111111-1111-4111-8111-111111111111', current_date, 'Out of town');
select pg_temp.assert_eq((select count(*) from task_skips), 1, 'A can log and read a skip');
select pg_temp.assert_raises(
  $$insert into task_skips (task_id, property_id, user_id, due_date) values
    ('2b2b2b2b-2222-4222-8222-dddddddddddd', '2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb',
     '11111111-1111-4111-8111-111111111111', current_date)$$,
  'A cannot log a skip against B''s task');
select pg_temp.assert_raises(
  $$insert into task_skips (task_id, property_id, user_id, due_date) values
    ('1a1a1a1a-1111-4111-8111-cccccccccccc', '2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb',
     '11111111-1111-4111-8111-111111111111', current_date)$$,
  'A cannot attach a skip to a property that is not theirs');

-- search_documents: finds by name, by OCR text (with a ** snippet) and by tag.
select pg_temp.assert_eq((select count(*) from search_documents('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', 'furnace', 10)), 1,
  'search finds the document by name');
select pg_temp.assert_true(
  (select position('**' in snippet) > 0 from search_documents('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', 'exchanger', 10) limit 1),
  'a text match returns a snippet with ** around the match');
select pg_temp.assert_eq((select count(*) from search_documents('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', 'roofing', 10)), 1,
  'search finds the document by tag');
select pg_temp.assert_eq((select count(*) from search_documents('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '   ', 10)), 0,
  'a blank query returns nothing');
select pg_temp.assert_eq((select count(*) from search_documents('2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb', 'furnace', 10)), 0,
  'A cannot search B''s property');
select pg_temp.assert_eq((select count(*) from search_documents('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', 'furnace', 0)), 1,
  'a limit of 0 is clamped to at least 1');
select soft_delete_document('1a1a1a1a-1111-4111-8111-111111112bbb');
select pg_temp.assert_eq((select count(*) from search_documents('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', 'roofing', 10)), 0,
  'search never returns a deleted document');

-- ── As user B ───────────────────────────────────────────────────────────────

reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}';

select pg_temp.assert_eq((select count(*) from task_skips), 0, 'B cannot read A''s skips');
delete from task_skips;
select pg_temp.assert_eq((select count(*) from task_skips), 0, 'B''s delete does not reach A''s skips');
select pg_temp.assert_eq((select count(*) from search_documents('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', 'furnace', 10)), 0,
  'B cannot search A''s property');
select pg_temp.assert_raises($$select restore_document('1a1a1a1a-1111-4111-8111-111111112bbb')$$,
  'B cannot restore A''s deleted document');
select pg_temp.assert_raises($$select soft_delete_document('1a1a1a1a-1111-4111-8111-111111111aaa')$$,
  'B cannot soft-delete A''s document');
select pg_temp.assert_raises($$select soft_delete_task('1a1a1a1a-1111-4111-8111-cccccccccccc')$$,
  'B cannot soft-delete A''s task');

-- A's skip is still there (checked as A).
reset role;
select pg_temp.assert_eq((select count(*) from task_skips), 1, 'A''s skip survived B''s delete');

-- ── Negative control: the harness must reject a false expectation ───────────

create function pg_temp.negative_control() returns text language plpgsql as $nc$
begin
  perform pg_temp.assert_eq((select count(*) from properties where false), 1, 'negative control');
  return 'BROKEN';
exception when others then
  return 'ok';
end $nc$;

select pg_temp.assert_eq(
  (select case when pg_temp.negative_control() = 'ok' then 1 else 0 end), 1,
  'the harness detects a wrong expectation');

select 'PASS: data-gap migration assertions held (incl. negative control)' as result;

rollback;
