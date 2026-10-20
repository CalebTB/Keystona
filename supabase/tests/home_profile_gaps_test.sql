-- Tests for 20261020130000_home_profile_gaps.sql
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
       v.label || '@home-test.invalid', crypt('x', gen_salt('bf')), now(), now(), now(), '', '', '', ''
from (values ('a', '11111111-1111-4111-8111-111111111111'::uuid),
             ('b', '22222222-2222-4222-8222-222222222222'::uuid)) as v(label, id);

insert into properties (id, user_id, address_line1, city, state, zip_code) values
  ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', '1 A St', 'Austin', 'TX', '78704'),
  ('2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222222', '2 B St', 'Austin', 'TX', '78704');
insert into systems (id, property_id, user_id, category, system_type, name) values
  ('1a1a1a1a-1111-4111-8111-5555555555aa', '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'hvac', 'furnace', 'A furnace'),
  ('2b2b2b2b-2222-4222-8222-5555555555bb', '2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222222', 'hvac', 'furnace', 'B furnace');
insert into appliances (id, property_id, user_id, category, appliance_type, name) values
  ('1a1a1a1a-1111-4111-8111-6666666666aa', '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'kitchen', 'fridge', 'A fridge');

-- New columns' defaults.
select pg_temp.assert_eq((select count(*) from properties where has_basement = false and id in ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa','2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb')), 2, 'has_basement defaults to false');
select pg_temp.assert_eq((select count(*) from systems where specifications = '{}'::jsonb and id in ('1a1a1a1a-1111-4111-8111-5555555555aa','2b2b2b2b-2222-4222-8222-5555555555bb')), 2, 'systems.specifications defaults to {}');
update systems set specifications = '{"fuel":"Natural gas","output":"80,000 BTU"}' where id = '1a1a1a1a-1111-4111-8111-5555555555aa';
select pg_temp.assert_eq((select count(*) from systems where id = '1a1a1a1a-1111-4111-8111-5555555555aa' and specifications ->> 'fuel' = 'Natural gas'), 1, 'specifications stores structured values');

-- Constraints (as the table owner).
select pg_temp.assert_raises(
  $$insert into item_service_log (property_id, user_id, kind, service_date, title)
    values ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'service', current_date, 'no item')$$,
  'a log entry needs a system or an appliance');
select pg_temp.assert_raises(
  $$insert into item_service_log (property_id, user_id, system_id, appliance_id, kind, service_date, title)
    values ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111',
            '1a1a1a1a-1111-4111-8111-5555555555aa', '1a1a1a1a-1111-4111-8111-6666666666aa', 'service', current_date, 'both')$$,
  'a log entry cannot have both a system and an appliance');
select pg_temp.assert_raises(
  $$insert into item_service_log (property_id, user_id, system_id, kind, service_date, title)
    values ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111',
            '1a1a1a1a-1111-4111-8111-5555555555aa', 'cleaned', current_date, 'bad kind')$$,
  'kind must be installed/purchased/service/repair');
select pg_temp.assert_raises(
  $$insert into item_service_log (property_id, user_id, system_id, kind, service_date, title, cost)
    values ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111',
            '1a1a1a1a-1111-4111-8111-5555555555aa', 'repair', current_date, 'neg', -5)$$,
  'a negative cost is rejected');

-- As user A.
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}';

insert into item_service_log (id, property_id, user_id, system_id, kind, service_date, title, provider, cost, under_warranty)
values ('aaaa0001-0000-4000-8000-000000000001', '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111',
        '1a1a1a1a-1111-4111-8111-5555555555aa', 'repair', current_date, 'Igniter replaced', 'Northline', 189.50, true);
insert into item_service_log (property_id, user_id, appliance_id, kind, service_date, title)
values ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111',
        '1a1a1a1a-1111-4111-8111-6666666666aa', 'purchased', current_date, 'Bought');
select pg_temp.assert_eq((select count(*) from item_service_log), 2, 'A logs entries on own system and appliance');

select pg_temp.assert_raises(
  $$insert into item_service_log (property_id, user_id, system_id, kind, service_date, title)
    values ('2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb', '11111111-1111-4111-8111-111111111111',
            '2b2b2b2b-2222-4222-8222-5555555555bb', 'service', current_date, 'on B system')$$,
  'A cannot log against B''s system or property');
select pg_temp.assert_raises(
  $$insert into item_service_log (property_id, user_id, system_id, kind, service_date, title)
    values ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111',
            '2b2b2b2b-2222-4222-8222-5555555555bb', 'service', current_date, 'B system on A property')$$,
  'A cannot attach a log to a system that is not theirs');
select pg_temp.assert_raises(
  $$insert into item_service_log (property_id, user_id, system_id, kind, service_date, title)
    values ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '22222222-2222-4222-8222-222222222222',
            '1a1a1a1a-1111-4111-8111-5555555555aa', 'service', current_date, 'as B')$$,
  'A cannot write a row as another user');

update item_service_log set title = 'Igniter and sensor replaced' where id = 'aaaa0001-0000-4000-8000-000000000001';
select pg_temp.assert_eq((select count(*) from item_service_log where title = 'Igniter and sensor replaced'), 1, 'A can edit own entry');

-- As user B: sees nothing, changes nothing.
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}';
select pg_temp.assert_eq((select count(*) from item_service_log), 0, 'B cannot read A''s log');
update item_service_log set title = 'hacked';
delete from item_service_log;

-- Back as A: the entries survived B's attempts, and A can delete their own.
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}';
select pg_temp.assert_eq((select count(*) from item_service_log where title <> 'hacked'), 2, 'B''s update/delete did not reach A''s log');
delete from item_service_log where id = 'aaaa0001-0000-4000-8000-000000000001';
select pg_temp.assert_eq((select count(*) from item_service_log), 1, 'A can delete own entry');

reset role;
-- Deleting the system removes its log (ON DELETE CASCADE).
delete from systems where id = '1a1a1a1a-1111-4111-8111-5555555555aa';
select pg_temp.assert_eq((select count(*) from item_service_log where system_id is not null), 0, 'a system''s log goes with it');

rollback;

select 'PASS: home-profile gap assertions held' as result;
