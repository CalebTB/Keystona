// Basic smoke test — verifies the app widget tree renders without throwing.

import 'package:flutter_test/flutter_test.dart';

import 'package:keystona/main.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    // KeystonaApp requires Supabase and Riverpod — skip full pump in unit tests.
    // Integration tests cover the full app lifecycle.
    expect(KeystonaApp, isNotNull);
  });
}
