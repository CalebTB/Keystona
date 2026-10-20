-- Tests for 20261020130100_item_service_log_ownership_checks.sql
-- BEGIN ... ROLLBACK against throwaway users; safe on any database.

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
       v.label || '@own-test.invalid', crypt('x', gen_salt('bf')), now(), now(), now(), '', '', '', ''
from (values ('a', '11111111-1111-4111-8111-111111111111'::uuid),
             ('b', '22222222-2222-4222-8222-222222222222'::uuid)) as v(label, id);

insert into properties (id, user_id, address_line1, city, state, zip_code) values
  ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', '1 A St', 'Austin', 'TX', '78704'),
  ('2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222222', '2 B St', 'Austin', 'TX', '78704');
insert into systems (id, property_id, user_id, category, system_type, name) values
  ('1a1a1a1a-1111-4111-8111-5555555555aa', '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'hvac', 'furnace', 'A furnace'),
  ('1a1a1a1a-1111-4111-8111-5555555555a2', '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'plumbing', 'heater', 'A heater'),
  ('2b2b2b2b-2222-4222-8222-5555555555bb', '2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222222', 'hvac', 'furnace', 'B furnace');
insert into documents (id, property_id, user_id, name, category_id, file_path)
select v.id, v.pid, v.uid, v.nm, (select id from document_categories order by created_at limit 1), v.path
from (values
  ('1a1a1a1a-1111-4111-8111-d00000000aaa'::uuid, '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa'::uuid, '11111111-1111-4111-8111-111111111111'::uuid, 'A doc', 'a/d.pdf'),
  ('2b2b2b2b-2222-4222-8222-d00000000bbb'::uuid, '2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb'::uuid, '22222222-2222-4222-8222-222222222222'::uuid, 'B doc', 'b/d.pdf')
) as v(id, pid, uid, nm, path)
where exists (select 1 from document_categories);

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}';

-- A can write entries against their own system and their own document.
insert into item_service_log (id, property_id, user_id, system_id, kind, service_date, title, document_id)
values ('aaaa0002-0000-4000-8000-000000000001', '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111',
        '1a1a1a1a-1111-4111-8111-5555555555aa', 'service', current_date, 'Tune-up', '1a1a1a1a-1111-4111-8111-d00000000aaa');
select pg_temp.assert_eq((select count(*) from item_service_log), 1, 'A logs an entry with their own document');
update item_service_log set system_id = '1a1a1a1a-1111-4111-8111-5555555555a2'
 where id = 'aaaa0002-0000-4000-8000-000000000001';
select pg_temp.assert_eq((select count(*) from item_service_log where system_id = '1a1a1a1a-1111-4111-8111-5555555555a2'), 1,
  'A can move an entry to another of their own systems');

-- The attacks the review found.
select pg_temp.assert_raises(
  $$update item_service_log set system_id = '2b2b2b2b-2222-4222-8222-5555555555bb'
    where id = 'aaaa0002-0000-4000-8000-000000000001'$$,
  'A cannot repoint an entry at B''s system');
select pg_temp.assert_raises(
  $$update item_service_log set document_id = '2b2b2b2b-2222-4222-8222-d00000000bbb'
    where id = 'aaaa0002-0000-4000-8000-000000000001'$$,
  'A cannot link an entry to B''s document (update)');
select pg_temp.assert_raises(
  $$insert into item_service_log (property_id, user_id, system_id, kind, service_date, title, document_id)
    values ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111',
            '1a1a1a1a-1111-4111-8111-5555555555aa', 'service', current_date, 'x', '2b2b2b2b-2222-4222-8222-d00000000bbb')$$,
  'A cannot link a new entry to B''s document (insert)');
select pg_temp.assert_raises(
  $$update item_service_log set appliance_id = '2b2b2b2b-2222-4222-8222-5555555555bb', system_id = null
    where id = 'aaaa0002-0000-4000-8000-000000000001'$$,
  'A cannot repoint an entry at an appliance id that is not theirs');

-- Unchanged after all the attempts.
select pg_temp.assert_eq((select count(*) from item_service_log
  where system_id = '1a1a1a1a-1111-4111-8111-5555555555a2' and document_id = '1a1a1a1a-1111-4111-8111-d00000000aaa'), 1,
  'the entry is unchanged after the rejected writes');

reset role;
rollback;

select 'PASS: item_service_log ownership checks held' as result;
