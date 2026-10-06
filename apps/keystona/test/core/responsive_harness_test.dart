import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/theme/aurora_scale.dart';

import '../support/responsive_harness.dart';

class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Scaffold(
      body: Padding(
        padding: a.all(16),
        child: const Text('Harness probe with some longer text to wrap'),
      ),
    );
  }
}

void main() {
  testResponsive('harness renders a probe screen', _Probe.new);

  test('compact widths scale tokens down, regular and tablet do not', () {
    expect(AuroraScale.minFactor, lessThan(1));
  });

  testWidgets('factor is 1 on regular, <1 on compact', (tester) async {
    late AuroraScale compact;
    late AuroraScale regular;
    await pumpScreen(
      tester,
      () => Builder(builder: (c) {
        compact = c.aurora;
        return const SizedBox.shrink();
      }),
      viewport: kViewports.first,
    );
    await pumpScreen(
      tester,
      () => Builder(builder: (c) {
        regular = c.aurora;
        return const SizedBox.shrink();
      }),
      viewport: kViewports[1],
    );
    expect(compact.factor, lessThan(1));
    expect(regular.factor, 1);
  });
}
