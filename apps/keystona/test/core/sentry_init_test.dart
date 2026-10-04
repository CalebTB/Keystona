import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/observability/sentry_init.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Tests the event-level scrubbing, not just the string rules.
///
/// `pii_scrubber_test.dart` proves the redaction patterns work. These prove
/// they are actually applied to every field of a SentryEvent that can carry
/// PII — the gap where a correct scrubber still leaks because it was wired to
/// only some fields.
void main() {
  group('scrubEvent — user', () {
    test('keeps the id and drops every other identity field', () {
      final event = SentryEvent(
        user: SentryUser(
          id: 'user-abc-123',
          email: 'caleb@example.com',
          username: 'calebbyers',
          name: 'Caleb Byers',
          ipAddress: '203.0.113.42',
        ),
      );

      final user = SentryInit.scrubEvent(event).user!;
      expect(user.id, 'user-abc-123', reason: 'id is the correlation key');
      expect(user.email, isNull);
      expect(user.username, isNull);
      expect(user.name, isNull);
      expect(user.ipAddress, isNull);
    });

    test('leaves a null user alone', () {
      expect(SentryInit.scrubEvent(SentryEvent()).user, isNull);
    });
  });

  group('scrubEvent — exceptions', () {
    test('redacts the exception value, keeps the type', () {
      final event = SentryEvent(
        exceptions: [
          SentryException(
            type: 'PostgrestException',
            value: 'DETAIL: Key (email)=(someone@gmail.com) already exists.',
          ),
        ],
      );

      final e = SentryInit.scrubEvent(event).exceptions!.single;
      expect(e.type, 'PostgrestException',
          reason: 'the type is what you triage on');
      expect(e.value, isNot(contains('someone@gmail.com')));
      expect(e.value, contains('Key (email)'),
          reason: 'the column name is the diagnostic signal');
    });

    test('scrubs every exception in a chain, not just the first', () {
      final event = SentryEvent(
        exceptions: [
          SentryException(type: 'A', value: 'first a@b.com'),
          SentryException(type: 'B', value: 'second c@d.com'),
          SentryException(type: 'C', value: 'third e@f.com'),
        ],
      );

      for (final e in SentryInit.scrubEvent(event).exceptions!) {
        expect(e.value, isNot(contains('@')), reason: 'leaked in ${e.type}');
      }
    });
  });

  group('scrubEvent — message', () {
    test('redacts the formatted text and any string params', () {
      final event = SentryEvent(
        message: SentryMessage(
          'upload failed for caleb@example.com',
          template: 'upload failed for %s',
          params: ['caleb@example.com', 42],
        ),
      );

      final m = SentryInit.scrubEvent(event).message!;
      expect(m.formatted, 'upload failed for [email]');
      expect(m.params![0], '[email]');
      expect(m.params![1], 42, reason: 'non-strings pass through untouched');
    });
  });

  group('scrubEvent — breadcrumbs', () {
    test('redacts breadcrumb message and data', () {
      final event = SentryEvent(
        breadcrumbs: [
          Breadcrumb(
            message: 'navigated with caleb@example.com',
            data: {
              'property_id': 'p-1',
              'address_line1': '742 Evergreen Terrace',
              'note': 'call 555-123-4567',
            },
          ),
        ],
      );

      final b = SentryInit.scrubEvent(event).breadcrumbs!.single;
      expect(b.message, 'navigated with [email]');
      expect(b.data!['property_id'], 'p-1', reason: 'ids are kept');
      expect(b.data!['address_line1'], '[redacted]');
      expect(b.data!['note'], isNot(contains('123-4567')));
    });
  });

  group('scrubEvent — tags', () {
    test('redacts PII-keyed tags and scrubs the rest', () {
      final event = SentryEvent(
        tags: {
          'email': 'caleb@example.com',
          'screen': 'task_detail',
          'note': 'sent to caleb@example.com',
        },
      );

      final tags = SentryInit.scrubEvent(event).tags!;
      expect(tags['email'], '[redacted]');
      expect(tags['screen'], 'task_detail', reason: 'useful, not PII');
      expect(tags['note'], 'sent to [email]');
    });
  });

  group('scrubEvent — dropped outright', () {
    test('request is removed: can carry tokens, no value on a client', () {
      final event = SentryEvent(
        request: SentryRequest(
          url: 'https://x.supabase.co/rest/v1/properties?select=*',
          headers: {'Authorization': 'Bearer secret-token'},
          cookies: 'session=abc',
        ),
      );
      expect(SentryInit.scrubEvent(event).request, isNull);
    });

    test('serverName is removed: identifies the machine', () {
      final event = SentryEvent()..serverName = "Calebs-MacBook-Pro.local";
      expect(SentryInit.scrubEvent(event).serverName, isNull);
    });
  });

  group('scrubBreadcrumb', () {
    test('handles null', () {
      expect(SentryInit.scrubBreadcrumb(null), isNull);
    });

    test('leaves a clean breadcrumb materially unchanged', () {
      final b = SentryInit.scrubBreadcrumb(
        Breadcrumb(message: 'tapped save', data: {'screen': 'task_form'}),
      )!;
      expect(b.message, 'tapped save');
      expect(b.data!['screen'], 'task_form');
    });
  });

  group('isEnabled', () {
    test('off without a DSN — safe to ship before Sentry exists', () {
      // AppConfig.sentryDsn is empty unless SENTRY_DSN is passed at build
      // time, and tests are not a release build. Both gates closed.
      expect(SentryInit.isEnabled, isFalse);
    });
  });

  // These are the regression tests for a bug that shipped silently: APP_ENV
  // defaulted to 'development' while the gate read `!isDevelopment`, so any
  // release build that didn't explicitly pass the define — an Xcode archive,
  // a bare `flutter build` — had crash reporting switched off with no
  // indication. Nothing failed; the dashboard was just empty.
  group('shouldEnable', () {
    const dsn = 'https://abc@o1.ingest.us.sentry.io/1';

    test('a release build with NO env define reports — the whole fix', () {
      // APP_ENV now defaults to 'production', so this is what a forgotten
      // --dart-define actually produces. It must be ON.
      expect(
        SentryInit.shouldEnable(
            dsn: dsn, isReleaseMode: true, appEnv: 'production'),
        isTrue,
      );
    });

    test('a release build EXPLICITLY marked development stays off', () {
      expect(
        SentryInit.shouldEnable(
            dsn: dsn, isReleaseMode: true, appEnv: 'development'),
        isFalse,
      );
    });

    test('debug builds stay off even when env says production', () {
      // kReleaseMode is the primary gate precisely because it cannot be
      // forgotten. Hot reloads must never spend quota.
      expect(
        SentryInit.shouldEnable(
            dsn: dsn, isReleaseMode: false, appEnv: 'production'),
        isFalse,
      );
    });

    test('staging opts in from a non-release build — app-run-staging', () {
      // The one deliberate exception: `make app-run-staging` exists to
      // exercise this instrumentation locally, which needs events to flow.
      expect(
        SentryInit.shouldEnable(
            dsn: dsn, isReleaseMode: false, appEnv: 'staging'),
        isTrue,
      );
    });

    test('staging in a release build also reports', () {
      expect(
        SentryInit.shouldEnable(
            dsn: dsn, isReleaseMode: true, appEnv: 'staging'),
        isTrue,
      );
    });

    test('an empty DSN wins over every other signal', () {
      for (final release in [true, false]) {
        for (final env in ['production', 'staging', 'development']) {
          expect(
            SentryInit.shouldEnable(
                dsn: '', isReleaseMode: release, appEnv: env),
            isFalse,
            reason: 'leaked with release=$release env=$env',
          );
        }
      }
    });
  });
}
