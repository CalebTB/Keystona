-- Tests for 20261020120000_completion_photo_kind.sql
-- Same harness and safety model as rls_boundaries_test.sql: BEGIN ... ROLLBACK
-- against throwaway users, safe on any database. Ends with a PASS line.

begin;

create function pg_temp.assert_eq(actual bigint, expected bigint, what text)
returns void language plpgsql as $$
begin
  if actual is distinct from expected then
    raise exception 'FAIL: % — expected %, got %', what, expected, actual;
  end if;
end $$;

create function pg_temp.assert_raises(stmt text, what text)
returns void language plpgsql as $$
begin
  execute stmt;
  raise exception 'FAIL: % — expected an error but the statement succeeded', what;
exception when others then
  if sqlerrm like 'FAIL:%' then raise; end if;
  return;
end $$;

insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
select '00000000-0000-0000-0000-000000000000', v.id, 'authenticated', 'authenticated',
       v.label || '@photo-test.invalid', crypt('x', gen_salt('bf')), now(), now(), now(), '', '', '', ''
from (values ('a', '11111111-1111-4111-8111-111111111111'::uuid),
             ('b', '22222222-2222-4222-8222-222222222222'::uuid)) as v(label, id);

insert into properties (id, user_id, address_line1, city, state, zip_code) values
  ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', '1 A St', 'Austin', 'TX', '78704');
insert into maintenance_tasks (id, property_id, user_id, name, category, due_date) values
  ('1a1a1a1a-1111-4111-8111-cccccccccccc', '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa',
   '11111111-1111-4111-8111-111111111111', 'A task', 'hvac', current_date);
insert into task_completions (id, task_id, user_id, property_id) values
  ('1a1a1a1a-1111-4111-8111-eeeeeeeeeeee', '1a1a1a1a-1111-4111-8111-cccccccccccc',
   '11111111-1111-4111-8111-111111111111', '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa');

-- The constraint: only before / after / NULL.
insert into completion_photos (completion_id, user_id, file_path, kind) values
  ('1a1a1a1a-1111-4111-8111-eeeeeeeeeeee', '11111111-1111-4111-8111-111111111111', 'p/before.jpg', 'before'),
  ('1a1a1a1a-1111-4111-8111-eeeeeeeeeeee', '11111111-1111-4111-8111-111111111111', 'p/after.jpg',  'after'),
  ('1a1a1a1a-1111-4111-8111-eeeeeeeeeeee', '11111111-1111-4111-8111-111111111111', 'p/other.jpg',  null);
select pg_temp.assert_eq((select count(*) from completion_photos
  where completion_id = '1a1a1a1a-1111-4111-8111-eeeeeeeeeeee'), 3, 'before, after and untagged photos are accepted');
select pg_temp.assert_raises(
  $$insert into completion_photos (completion_id, user_id, file_path, kind)
    values ('1a1a1a1a-1111-4111-8111-eeeeeeeeeeee', '11111111-1111-4111-8111-111111111111', 'p/x.jpg', 'middle')$$,
  'a kind other than before/after is rejected');

-- Owners read their own photos by kind; another user sees none.
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}';
select pg_temp.assert_eq((select count(*) from completion_photos where kind = 'before'), 1, 'owner filters by kind');

reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}';
select pg_temp.assert_eq((select count(*) from completion_photos), 0, 'another user sees no photos');

reset role;
rollback;

select 'PASS: completion_photos.kind assertions held' as result;
