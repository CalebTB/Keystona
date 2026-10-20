import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/providers/provider_retry.dart';

void main() {
  test('a failing provider is not retried automatically', () async {
    var calls = 0;
    final failing = FutureProvider<int>((ref) async {
      calls++;
      throw Exception('offline');
    });
    final container = ProviderContainer(retry: noAutomaticRetry);
    addTearDown(container.dispose);

    await expectLater(container.read(failing.future), throwsException);
    // Riverpod's default first retry is after 200 ms; wait well past it.
    await Future<void>.delayed(const Duration(milliseconds: 900));

    expect(calls, 1);
    expect(container.read(failing).hasError, isTrue);
  });

  test('the default policy DOES retry (so the test above is meaningful)', () async {
    var calls = 0;
    final failing = FutureProvider<int>((ref) async {
      calls++;
      throw Exception('offline');
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(failing, (_, _) {});
    addTearDown(sub.close);

    await Future<void>.delayed(const Duration(milliseconds: 900));

    expect(calls, greaterThan(1));
  });
}
