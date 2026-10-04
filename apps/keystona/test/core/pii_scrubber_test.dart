import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/observability/pii_scrubber.dart';

/// These tests are the enforcement mechanism for Security Guide §5.4 and the
/// §8 checklist item "No PII in error reports". A scrubber that silently
/// stops scrubbing is worse than no scrubber, because it buys false
/// confidence — so each PII class gets an explicit case, and the
/// "keeps diagnostics" group guards against over-redaction making reports
/// useless.
void main() {
  group('redactText — removes PII', () {
    test('emails', () {
      expect(
        PiiScrubber.redactText('login failed for caleb@example.com'),
        'login failed for [email]',
      );
    });

    test('emails inside a Postgres unique-violation detail', () {
      // The realistic shape: Postgres echoes the offending value back.
      const input =
          'duplicate key value violates unique constraint "users_email_key" '
          'DETAIL: Key (email)=(someone@gmail.com) already exists.';
      final out = PiiScrubber.redactText(input);
      expect(out, contains('users_email_key'),
          reason: 'constraint name is the diagnostic value — must survive');
      expect(out, contains('Key (email)'),
          reason: 'column name identifies the problem — must survive');
      expect(out, isNot(contains('someone@gmail.com')));
      expect(out, isNot(contains('gmail')));
    });

    test('phone numbers in several formats', () {
      for (final p in [
        '+1 (555) 123-4567',
        '555-123-4567',
        '5551234567',
        '555.123.4567',
      ]) {
        final out = PiiScrubber.redactText('call $p now');
        expect(out, isNot(contains('1234567')), reason: 'failed on: $p');
        expect(out, isNot(contains('555123')), reason: 'failed on: $p');
      }
    });

    test('street addresses', () {
      for (final a in [
        '742 Evergreen Terrace',
        '1600 Pennsylvania Ave',
        '10 Downing Street',
        '350 Fifth Avenue',
      ]) {
        final out = PiiScrubber.redactText('property at $a was updated');
        expect(out, contains('[address]'), reason: 'failed on: $a');
        expect(out, isNot(contains('Evergreen')), reason: 'failed on: $a');
      }
    });

    test('zip codes, when context marks them as such', () {
      expect(PiiScrubber.redactText('zip 78704'), 'zip [zip]');
      expect(PiiScrubber.redactText('zip 78704-1234'), 'zip [zip]');
      expect(PiiScrubber.redactText('Austin TX 78704'), 'Austin TX [zip]');
    });

    test('a bare 5-digit number survives — documented tradeoff', () {
      // Required so Postgres error codes stay readable. Five digits alone
      // identify nobody; losing every error code would cost real
      // debuggability. Structured address fields are caught by isPiiKey.
      expect(PiiScrubber.redactText('code: 42501'), 'code: 42501');
      expect(PiiScrubber.redactText('23505'), '23505');
    });

    test('JWTs — highest priority, payload can embed an email', () {
      const jwt =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.abc123xyz';
      final out = PiiScrubber.redactText('token=$jwt expired');
      expect(out, 'token=[jwt] expired');
    });

    test('bearer tokens', () {
      final out = PiiScrubber.redactText('Authorization: Bearer sk_live_abc123');
      expect(out, isNot(contains('sk_live_abc123')));
      expect(out, contains('[token]'));
    });

    test('the real auth error we hit — must not leak the address', () {
      const input =
          'AuthRetryableFetchException: failed for dev@keystona.app at '
          '742 Evergreen Terrace, Austin TX 78704 (555) 867-5309';
      final out = PiiScrubber.redactText(input);
      expect(out, contains('AuthRetryableFetchException'),
          reason: 'exception type is the whole point of the report');
      for (final leak in [
        'dev@keystona.app',
        'Evergreen',
        '78704',
        '867-5309',
      ]) {
        expect(out, isNot(contains(leak)), reason: 'leaked: $leak');
      }
    });

    test('handles null and empty without throwing', () {
      expect(PiiScrubber.redactText(null), '');
      expect(PiiScrubber.redactText(''), '');
    });
  });

  group('redactText — keeps diagnostics', () {
    test('UUIDs survive: identifiers, not personal data', () {
      const id = '3f2504e0-4f89-11d3-9a0c-0305e82c3301';
      expect(PiiScrubber.redactText('property_id=$id'), contains(id));
    });

    test('Postgres error codes and table names survive', () {
      const input =
          'PostgrestException(message: permission denied for table '
          'project_phase_templates, code: 42501)';
      final out = PiiScrubber.redactText(input);
      expect(out, contains('42501'));
      expect(out, contains('project_phase_templates'));
      expect(out, contains('permission denied'));
    });

    test('stack-trace-ish text survives', () {
      const input =
          '#3 _AuroraTextFieldState.build (package:keystona/core/widgets/'
          'aurora/aurora_text_field.dart:121:18)';
      final out = PiiScrubber.redactText(input);
      expect(out, contains('aurora_text_field.dart'));
      expect(out, contains('_AuroraTextFieldState'));
    });
  });

  group('isPiiKey', () {
    test('flags identity, address, phone and free-text columns', () {
      for (final k in [
        'email', 'full_name', 'address_line1', 'city', 'zip_code',
        'phone_primary', 'claims_phone', 'policy_number', 'notes',
        'ocr_text', 'serial_number', 'location_description', 'caption',
      ]) {
        expect(PiiScrubber.isPiiKey(k), isTrue, reason: 'missed: $k');
      }
    });

    test('is case-insensitive', () {
      expect(PiiScrubber.isPiiKey('EMAIL'), isTrue);
      expect(PiiScrubber.isPiiKey('Address_Line1'), isTrue);
    });

    test('allows ids, timestamps and counts through', () {
      for (final k in [
        'id', 'user_id', 'property_id', 'task_id', 'created_at',
        'updated_at', 'deleted_at', 'phase_count', 'status', 'category',
      ]) {
        expect(PiiScrubber.isPiiKey(k), isFalse, reason: 'over-redacted: $k');
      }
    });

    test('catches unanticipated keys by fragment', () {
      for (final k in [
        'user_email_backup', 'home_phone', 'api_key', 'refresh_token',
        'billing_address', 'ocr_result',
      ]) {
        expect(PiiScrubber.isPiiKey(k), isTrue, reason: 'missed: $k');
      }
    });
  });

  group('redactMap', () {
    test('redacts PII keys and keeps correlation ids', () {
      final out = PiiScrubber.redactMap({
        'user_id': 'abc-123',
        'email': 'caleb@example.com',
        'address_line1': '742 Evergreen Terrace',
        'status': 'overdue',
        'phase_count': 4,
      });
      expect(out['user_id'], 'abc-123');
      expect(out['status'], 'overdue');
      expect(out['phase_count'], 4);
      expect(out['email'], PiiScrubber.redacted);
      expect(out['address_line1'], PiiScrubber.redacted);
    });

    test('catches PII hiding under an innocent key name', () {
      final out = PiiScrubber.redactMap({
        'message': 'could not reach caleb@example.com',
      });
      expect(out['message'], 'could not reach [email]');
    });

    test('recurses into nested maps and lists', () {
      final out = PiiScrubber.redactMap({
        'task': {
          'id': 't-1',
          'notes': 'call the plumber',
          'nested': {'email': 'a@b.com'},
        },
        'contacts': [
          {'name': 'Bob', 'id': 'c-1'},
          {'name': 'Alice', 'id': 'c-2'},
        ],
      });
      final task = out['task'] as Map<String, dynamic>;
      expect(task['id'], 't-1');
      expect(task['notes'], PiiScrubber.redacted);
      expect((task['nested'] as Map)['email'], PiiScrubber.redacted);
      final contacts = out['contacts'] as List;
      expect((contacts[0] as Map)['name'], PiiScrubber.redacted);
      expect((contacts[0] as Map)['id'], 'c-1');
    });

    test('handles null, and preserves non-string scalars', () {
      expect(PiiScrubber.redactMap(null), isEmpty);
      final out = PiiScrubber.redactMap({
        'count': 3,
        'ratio': 1.5,
        'flag': true,
        'nothing': null,
      });
      expect(out['count'], 3);
      expect(out['ratio'], 1.5);
      expect(out['flag'], true);
      expect(out['nothing'], isNull);
    });
  });
}
