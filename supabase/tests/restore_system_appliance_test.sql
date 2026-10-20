-- Tests for 20261020140000_restore_system_appliance.sql
-- BEGIN ... ROLLBACK against throwaway users; safe on any database.

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
  if actual is distinct from true then raise exception 'FAIL: % — expected true, got %', what, actual; end if;
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
       v.label || '@restore-test.invalid', crypt('x', gen_salt('bf')), now(), now(), now(), '', '', '', ''
from (values ('a', '11111111-1111-4111-8111-111111111111'::uuid),
             ('b', '22222222-2222-4222-8222-222222222222'::uuid)) as v(label, id);
insert into properties (id, user_id, address_line1, city, state, zip_code) values
  ('1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', '1 A St', 'Austin', 'TX', '78704'),
  ('2b2b2b2b-2222-4222-8222-bbbbbbbbbbbb', '22222222-2222-4222-8222-222222222222', '2 B St', 'Austin', 'TX', '78704');
insert into systems (id, property_id, user_id, category, system_type, name) values
  ('1a1a1a1a-1111-4111-8111-5555555555aa', '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'hvac', 'furnace', 'A furnace');
insert into appliances (id, property_id, user_id, category, appliance_type, name) values
  ('1a1a1a1a-1111-4111-8111-6666666666aa', '1a1a1a1a-1111-4111-8111-aaaaaaaaaaaa', '11111111-1111-4111-8111-111111111111', 'kitchen', 'fridge', 'A fridge');

select pg_temp.assert_true(not has_function_privilege('anon', 'public.restore_system(uuid)', 'execute'), 'anon cannot call restore_system');
select pg_temp.assert_true(not has_function_privilege('anon', 'public.restore_appliance(uuid)', 'execute'), 'anon cannot call restore_appliance');
select pg_temp.assert_true(has_function_privilege('authenticated', 'public.restore_system(uuid)', 'execute'), 'authenticated can call restore_system');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}';

select soft_delete_system('1a1a1a1a-1111-4111-8111-5555555555aa');
select soft_delete_appliance('1a1a1a1a-1111-4111-8111-6666666666aa');
select pg_temp.assert_eq((select count(*) from systems where id = '1a1a1a1a-1111-4111-8111-5555555555aa'), 0, 'a deleted system is hidden');
select pg_temp.assert_eq((select count(*) from appliances where id = '1a1a1a1a-1111-4111-8111-6666666666aa'), 0, 'a deleted appliance is hidden');

select restore_system('1a1a1a1a-1111-4111-8111-5555555555aa');
select restore_appliance('1a1a1a1a-1111-4111-8111-6666666666aa');
select pg_temp.assert_eq((select count(*) from systems where id = '1a1a1a1a-1111-4111-8111-5555555555aa'), 1, 'restore_system brings it back');
select pg_temp.assert_eq((select count(*) from appliances where id = '1a1a1a1a-1111-4111-8111-6666666666aa'), 1, 'restore_appliance brings it back');
select pg_temp.assert_raises($$select restore_system('1a1a1a1a-1111-4111-8111-5555555555aa')$$, 'restoring a live system raises');

-- Another user can neither restore nor probe.
select soft_delete_system('1a1a1a1a-1111-4111-8111-5555555555aa');
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}';
select pg_temp.assert_raises($$select restore_system('1a1a1a1a-1111-4111-8111-5555555555aa')$$, 'B cannot restore A''s system');
select pg_temp.assert_raises($$select restore_appliance('1a1a1a1a-1111-4111-8111-6666666666aa')$$, 'B cannot restore a live appliance of A''s');

reset role;
rollback;

select 'PASS: restore_system / restore_appliance assertions held' as result;
