import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/providers/provider_retry.dart';
import 'package:keystona/features/auth/providers/auth_provider.dart';
import 'package:keystona/features/home_profile/models/property_edits.dart';
import 'package:keystona/features/home_profile/providers/home_profile_provider.dart';
import 'package:keystona/features/home_profile/providers/home_repositories.dart';

import 'track_a_support.dart';

class _Session extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;
}

final _session = NotifierProvider<_Session, bool>(_Session.new);

void main() {
  test('the kept-alive overview does not outlive the session', () async {
    final properties = FakePropertyRepository(sampleProperty());
    final container = ProviderContainer(
      retry: noAutomaticRetry,
      overrides: [
        isAuthenticatedProvider.overrideWith((ref) => ref.watch(_session)),
        propertyRepositoryProvider.overrideWithValue(properties),
        homeItemsRepositoryProvider.overrideWithValue(
          FakeHomeItemsRepository(sampleItems()),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(homeProfileProvider, (_, _) {});
    addTearDown(sub.close);

    final first = await container.read(homeProfileProvider.future);
    expect(first.property.addressLine1, '1428 Elm Hollow Ln');
    expect(first.systemCount, 3);
    expect(first.applianceCount, 2);

    // Signed out: the cache is dropped, nothing of the last user shows.
    container.read(_session.notifier).set(false);
    await container.pump();
    await expectLater(
      container.read(homeProfileProvider.future),
      throwsA(isA<NoPropertyException>()),
    );

    // Signed in as someone else: a fresh read.
    properties.property = sampleProperty().copyWith(addressLine1: '9 Other St');
    container.read(_session.notifier).set(true);
    await container.pump();
    final second = await container.read(homeProfileProvider.future);
    expect(second.property.addressLine1, '9 Other St');
  });

  test(
    'saving re-reads the overview and a failed save leaves it alone',
    () async {
      final properties = FakePropertyRepository(sampleProperty());
      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(true),
          propertyRepositoryProvider.overrideWithValue(properties),
          homeItemsRepositoryProvider.overrideWithValue(
            FakeHomeItemsRepository(sampleItems()),
          ),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(homeProfileProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(homeProfileProvider.future);
      final notifier = container.read(homeProfileProvider.notifier);

      properties.failSave = true;
      await expectLater(
        notifier.saveEdits(_edits()),
        throwsA(isA<StateError>()),
      );
      expect(
        container.read(homeProfileProvider).value?.property.city,
        'Springfield',
      );

      properties.failSave = false;
      properties.property = sampleProperty().copyWith(city: 'Huntsville');
      await notifier.saveEdits(_edits());
      expect(properties.saved, hasLength(1));
      expect(
        container.read(homeProfileProvider).value?.property.city,
        'Huntsville',
      );
    },
  );
}

PropertyEdits _edits() => const PropertyEdits(
  addressLine1: '1428 Elm Hollow Ln',
  city: 'Huntsville',
  state: 'AL',
  zipCode: '35758',
  hasBasement: true,
);
