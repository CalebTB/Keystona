import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A device viewport used by the responsive harness.
class TestViewport {
  const TestViewport(this.name, this.size);
  final String name;
  final Size size;
}

/// Every screen must render without overflow at all of these.
const List<TestViewport> kViewports = [
  TestViewport('small phone 320x568', Size(320, 568)),
  TestViewport('phone 390x844', Size(390, 844)),
  TestViewport('large phone 430x932', Size(430, 932)),
  TestViewport('landscape phone 844x390', Size(844, 390)),
  TestViewport('tablet 834x1194', Size(834, 1194)),
];

const List<double> kTextScales = [1.0, 1.5, 2.0];

/// Pumps [build] in a [MaterialApp] at [viewport] and [textScale].
Future<void> pumpScreen(
  WidgetTester tester,
  Widget Function() build, {
  required TestViewport viewport,
  double textScale = 1.0,
  Widget Function(Widget child)? wrap,
}) async {
  tester.view.physicalSize = viewport.size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final app = MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: build(),
  );
  await tester.pumpWidget(wrap == null ? app : wrap(app));
  await tester.pump();
}

/// Registers one test per viewport x text scale that fails on any layout
/// exception (RenderFlex overflow, unbounded constraints, ...).
void testResponsive(
  String description,
  Widget Function() build, {
  Widget Function(Widget child)? wrap,
}) {
  for (final viewport in kViewports) {
    for (final scale in kTextScales) {
      testWidgets('$description @ ${viewport.name}, text x$scale', (tester) async {
        await pumpScreen(
          tester,
          build,
          viewport: viewport,
          textScale: scale,
          wrap: wrap,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
