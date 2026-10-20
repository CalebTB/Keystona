import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/onboarding/models/onboarding_models.dart';
import 'package:keystona/features/onboarding/providers/onboarding_provider.dart';

void main() {
  test('the onboarding property draft does not survive a change of user', () {
    final signedInUser = StateProvider<String>((_) => 'user-a');
    final container = ProviderContainer(
      overrides: [
        onboardingUserIdProvider.overrideWith((ref) => ref.watch(signedInUser)),
      ],
    );
    addTearDown(container.dispose);

    // A is signed in and fills in an address.
    container.listen(onbPropertyDraftProvider, (_, _) {});
    container.read(onbPropertyDraftProvider.notifier).set(
      const OnbPropertyDraft(
        address: OnbAddress(
          street: '1 A St',
          city: 'Austin',
          state: 'TX',
          zip: '78704',
        ),
        kind: HomeKind.singleFamily,
      ),
    );
    expect(container.read(onbPropertyDraftProvider), isNotNull);

    // B signs in on the same device: they must not see A's address.
    container.read(signedInUser.notifier).state = 'user-b';
    expect(container.read(onbPropertyDraftProvider), isNull);
  });
}
