-- RLS boundary tests: can user A reach user B's data?
--
-- CLAUDE.md calls RLS "the auth layer". Until this file existed, nothing
-- verified that claim — the policies were written, reviewed by eye, and
-- trusted. These tests are the enforcement mechanism.
--
-- HOW IT WORKS
--   Supabase derives auth.uid() from the `request.jwt.claims` GUC, so a plain
--   SQL session can impersonate a user by setting it. Combined with
--   `set local role authenticated` that exercises the real policies — the same
--   code path PostgREST takes — with no app, no network and no Docker.
--
-- SAFETY
--   The whole script runs inside BEGIN ... ROLLBACK. It seeds two throwaway
--   users, asserts against them, and discards everything. Nothing persists,
--   so it is safe to run against any database including production.
--   It never reads or asserts on real user rows.
--
-- HOW TO RUN
--   psql "$SUPABASE_DB_URL" -f supabase/tests/rls_boundaries_test.sql
--   (or paste into the SQL editor / run via the Supabase MCP execute_sql)
--
--   Silence is NOT success — the final SELECT prints a PASS line. Any failed
--   assertion aborts with `FAIL: <what>` and rolls back.

begin;

-- ── Assertion helpers ───────────────────────────────────────────────────────
-- Created before any role switch, because `authenticated` cannot create
-- functions. pg_temp is dropped with the session.

create function pg_temp.assert_eq(actual bigint, expected bigint, what text)
returns void language plpgsql as $$
begin
  if actual is distinct from expected then
    raise exception 'FAIL: % — expected %, got %', what, expected, actual;
  end if;
end $$;

-- A write that RLS blocks shows up two different ways depending on the
-- statement: UPDATE/DELETE silently match zero rows (USING filtered them out),
-- while INSERT raises 42501 (WITH CHECK rejected it). Both are "blocked";
-- a test that only looked for one would pass while the other leaked.
create function pg_temp.assert_insert_blocked(stmt text, what text)
returns void language plpgsql as $$
begin
  execute stmt;
  raise exception 'FAIL: % — the insert SUCCEEDED and should have been denied', what;
exception
  when insufficient_privilege then return;  -- 42501, the expected outcome
  when others then
    if sqlstate = 'P0001' and sqlerrm like 'FAIL:%' then raise; end if;
    raise exception 'FAIL: % — denied, but with % (%) rather than 42501',
      what, sqlstate, sqlerrm;
end $$;

-- ── Fixtures ────────────────────────────────────────────────────────────────
-- Two users with one property each and one row per table under test.
--
-- The empty strings on the token columns are load-bearing: GoTrue scans them
-- into non-nullable Go strings, and a NULL there produces a 500 on the next
-- auth request. Harmless here (we roll back) but kept correct so this insert
-- can be copied elsewhere without reintroducing that bug.

-- Fixed UUIDs rather than a temp table: `authenticated` has no privileges on
-- another role's pg_temp schema, so a temp lookup table raises 42501 the moment
-- the first impersonated assertion reads it. Literals need no grants.
--
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
       'authenticated', v.label || '@rls-test.invalid',
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

insert into task_completions (task_id, user_id, property_id)
values
  ('1a1a1a1a-1111-4111-8111-cccccccccccc', '11111111-1111-4111-8111-111111111111', '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa'),
  ('2b2b2b2b-2222-4222-8222-dddddddddddd', '22222222-2222-4222-8222-222222222222', '2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb');

insert into systems (property_id, user_id, category, system_type, name)
values
  ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'hvac', 'furnace', 'A furnace'),
  ('2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222222', 'hvac', 'furnace', 'B furnace');

insert into appliances (property_id, user_id, category, appliance_type, name)
values
  ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'kitchen', 'fridge', 'A fridge'),
  ('2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222222', 'kitchen', 'fridge', 'B fridge');

insert into emergency_contacts (property_id, user_id, name, category, phone_primary)
values
  ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'A plumber', 'plumber', '555-0100'),
  ('2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222222', 'B plumber', 'plumber', '555-0200');

insert into insurance_info (property_id, user_id, policy_type, carrier)
values
  ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'homeowners', 'A Insurance'),
  ('2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222222', 'homeowners', 'B Insurance');

insert into projects (property_id, user_id, name)
values
  ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'A project'),
  ('2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222222', 'B project');

-- Documents need a category_id. Reuse a system category rather than creating
-- one, so this test does not depend on document_categories' own policies.
insert into documents (property_id, user_id, name, category_id, file_path)
select v.pid, v.uid, v.nm,
       (select id from document_categories order by created_at limit 1),
       v.path
from (values
  ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa'::uuid, '11111111-1111-4111-8111-111111111111'::uuid, 'A doc', 'a/doc.pdf'),
  ('2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb'::uuid, '22222222-2222-4222-8222-222222222222'::uuid, 'B doc', 'b/doc.pdf')
) as v(pid, uid, nm, path)
where exists (select 1 from document_categories);

-- ── READ isolation ──────────────────────────────────────────────────────────
-- Each user must see exactly their own row. Asserting "= 1" rather than
-- "<> 2" matters: a policy that hides everything would also satisfy "<> 2",
-- and a test that passes on a totally broken policy is worse than no test.

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}';

select pg_temp.assert_eq((select count(*) from properties),         1, 'A reads only own properties');
select pg_temp.assert_eq((select count(*) from maintenance_tasks),  1, 'A reads only own maintenance_tasks');
select pg_temp.assert_eq((select count(*) from task_completions),   1, 'A reads only own task_completions');
select pg_temp.assert_eq((select count(*) from systems),            1, 'A reads only own systems');
select pg_temp.assert_eq((select count(*) from appliances),         1, 'A reads only own appliances');
select pg_temp.assert_eq((select count(*) from emergency_contacts), 1, 'A reads only own emergency_contacts');
select pg_temp.assert_eq((select count(*) from insurance_info),     1, 'A reads only own insurance_info');
select pg_temp.assert_eq((select count(*) from projects),           1, 'A reads only own projects');

-- Targeted probe: not just "a count of 1" but "B's specific row is invisible".
-- A policy keyed on the wrong column could return one row that is the wrong one.
select pg_temp.assert_eq(
  (select count(*) from properties where id = '2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb'), 0,
  'A cannot read B''s property by id');
select pg_temp.assert_eq(
  (select count(*) from maintenance_tasks where id = '2b2b2b2b-2222-4222-8222-dddddddddddd'), 0,
  'A cannot read B''s task by id');

reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}';

select pg_temp.assert_eq((select count(*) from properties),        1, 'B reads only own properties');
select pg_temp.assert_eq((select count(*) from maintenance_tasks), 1, 'B reads only own maintenance_tasks');
select pg_temp.assert_eq((select count(*) from projects),          1, 'B reads only own projects');
select pg_temp.assert_eq(
  (select count(*) from properties where id = '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa'), 0,
  'B cannot read A''s property by id');

-- ── WRITE isolation ─────────────────────────────────────────────────────────
-- Read isolation alone is not enough: a SELECT policy can be correct while
-- UPDATE/DELETE/INSERT are wide open.

reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}';

-- UPDATE/DELETE are filtered by USING, so they match zero rows rather than error.
with updated as (
  update maintenance_tasks set name = 'HIJACKED'
   where id = '2b2b2b2b-2222-4222-8222-dddddddddddd' returning 1
)
select pg_temp.assert_eq((select count(*) from updated), 0,
  'A cannot UPDATE B''s maintenance_task');

with updated as (
  update properties set city = 'HIJACKED'
   where id = '2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb' returning 1
)
select pg_temp.assert_eq((select count(*) from updated), 0,
  'A cannot UPDATE B''s property');

with deleted as (
  delete from emergency_contacts
   where user_id = '22222222-2222-4222-8222-222222222222' returning 1
)
select pg_temp.assert_eq((select count(*) from deleted), 0,
  'A cannot DELETE B''s emergency_contact');

-- INSERT is rejected by WITH CHECK, which raises 42501.
-- Forging user_id is the attack CLAUDE.md warns about: "never trust
-- client-supplied user_id".
select pg_temp.assert_insert_blocked($$
  insert into maintenance_tasks (property_id, user_id, name, category, due_date)
  values ('2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb',
          '22222222-2222-4222-8222-222222222222',
          'forged', 'hvac', current_date)
$$, 'A cannot INSERT a task owned by B');

select pg_temp.assert_insert_blocked($$
  insert into projects (property_id, user_id, name)
  values ('2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb',
          '22222222-2222-4222-8222-222222222222', 'forged')
$$, 'A cannot INSERT a project owned by B');

-- Writing into B's property while claiming A's own user_id. Catches a policy
-- that checks user_id but forgets to verify the property belongs to the caller.
select pg_temp.assert_insert_blocked($$
  insert into maintenance_tasks (property_id, user_id, name, category, due_date)
  values ('2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb',
          '11111111-1111-4111-8111-111111111111',
          'cross-property', 'hvac', current_date)
$$, 'A cannot INSERT into B''s property even under own user_id');

-- ── Anonymous access ────────────────────────────────────────────────────────
-- An unauthenticated caller must see nothing. auth.uid() is NULL here, and a
-- policy written as `user_id = auth.uid()` yields NULL (not true), so this
-- should be empty — but an accidentally permissive policy would show up here.

reset role;
set local role anon;
set local "request.jwt.claims" = '';

select pg_temp.assert_eq((select count(*) from properties),         0, 'anon reads no properties');
select pg_temp.assert_eq((select count(*) from documents),          0, 'anon reads no documents');
select pg_temp.assert_eq((select count(*) from maintenance_tasks),  0, 'anon reads no maintenance_tasks');
select pg_temp.assert_eq((select count(*) from emergency_contacts), 0, 'anon reads no emergency_contacts');
select pg_temp.assert_eq((select count(*) from insurance_info),     0, 'anon reads no insurance_info');

reset role;

-- ── Negative control ────────────────────────────────────────────────────────
-- Everything above is a list of assertions that passed. That is only
-- meaningful if a WRONG assertion would have failed — a harness with a broken
-- comparison would print PASS for a wide-open database. So assert that
-- assert_eq itself still rejects a false expectation.

create function pg_temp.negative_control() returns text language plpgsql as $nc$
begin
  perform pg_temp.assert_eq((select count(*) from properties where false), 1, 'negative control');
  return 'BROKEN';
exception when others then
  return 'ok';  -- it raised, as it must
end $nc$;

select pg_temp.assert_eq(
  (select case when pg_temp.negative_control() = 'ok' then 1 else 0 end), 1,
  'the harness detects a wrong expectation');

select 'PASS: all RLS boundary assertions held (incl. negative control)' as result;

rollback;
