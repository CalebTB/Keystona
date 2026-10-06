import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/onboarding/models/onboarding_models.dart';
import 'package:keystona/features/onboarding/services/address_parser.dart';
import 'package:keystona/features/onboarding/services/climate_lookup.dart';
import 'package:keystona/features/onboarding/services/onboarding_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ClimateLookup', () {
    test('kit example: ZIP 35758 is mixed-humid 4A with three reminders', () {
      final c = ClimateLookup.forZip('35758', 'AL')!;
      expect(c.zoneLabel, '4A');
      expect(c.label, 'mixed-humid');
      expect(c.reminders.map((r) => r.title), [
        'Drain outdoor faucets',
        'Service the AC before summer',
        'Check the crawlspace for moisture',
      ]);
    });

    test('falls back to the state zone', () {
      expect(ClimateLookup.forZip('55401', 'MN')!.zone, 6);
    });

    test('rejects malformed ZIPs and unknown states', () {
      expect(ClimateLookup.forZip('1234', 'AL'), isNull);
      expect(ClimateLookup.forZip('99999', 'ZZ'), isNull);
    });

    test('every state maps to a zone from 1 to 7', () {
      for (final s in ['AK', 'FL', 'HI', 'ND', 'CA', 'TX']) {
        final z = ClimateLookup.forZip('00000', s)!.zone;
        expect(z, inInclusiveRange(1, 7));
      }
    });
  });

  group('AddressParser', () {
    test('parses street, city, state and ZIP', () {
      final s = AddressParser.suggest('1428 Elm Hollow Ln, Springfield, AL 35758');
      expect(s, hasLength(1));
      expect(s.first.street, '1428 Elm Hollow Ln');
      expect(s.first.city, 'Springfield');
      expect(s.first.state, 'AL');
      expect(s.first.zip, '35758');
    });

    test('returns nothing for partial text', () {
      expect(AddressParser.suggest('1428 Elm Hol'), isEmpty);
      expect(AddressParser.suggest('14'), isEmpty);
    });
  });

  group('OnboardingProgress', () {
    test('round-trips through json', () {
      const p = OnboardingProgress(
        persona: OnboardingPersona.shopper,
        stage: OnbStage.trial,
        trialStarted: true,
        doneSteps: {ChecklistStep.scan, ChecklistStep.document},
      );
      final back = OnboardingProgress.fromJson(p.toJson());
      expect(back.persona, OnboardingPersona.shopper);
      expect(back.stage, OnbStage.trial);
      expect(back.trialStarted, isTrue);
      expect(back.doneSteps, {ChecklistStep.scan, ChecklistStep.document});
    });

    test('prefs store keeps progress per user (resume)', () async {
      SharedPreferences.setMockInitialValues({});
      const store = PrefsOnboardingProgressStore();
      await store.save(
        'a',
        const OnboardingProgress(stage: OnbStage.checklist),
      );
      expect((await store.load('a')).stage, OnbStage.checklist);
      expect((await store.load('b')).stage, OnbStage.persona);
    });
  });
}
