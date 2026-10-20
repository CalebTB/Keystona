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

/// Run the FULL 5 viewports x 3 text scales matrix (15 cases per screen):
///   flutter test --dart-define=FULL_MATRIX=true
/// Do this before a release. Day to day, the curated set below runs instead.
const bool kFullMatrix = bool.fromEnvironment('FULL_MATRIX');

/// The viewports responsive tests loop over by default.
///
/// Chosen as the worst cases rather than every combination: the smallest
/// phone (width pressure), a landscape phone (height pressure), the reference
/// phone, and a tablet (content width cap). Together with [scalesFor] this is
/// 5 cases per screen instead of 15, and it still catches the overflows the
/// full matrix found in practice.
List<TestViewport> get activeViewports => kFullMatrix
    ? kViewports
    : [kViewports[0], kViewports[1], kViewports[3], kViewports[4]];

/// The text scales to run at [viewport] by default.
///   - 320x568 at 2.0: the strictest width case.
///   - 390x844 at 1.0 and 1.5: the reference phone, plus the scale at which
///     layouts start to stack.
///   - 844x390 landscape at 1.5: height pressure.
///   - 834x1194 tablet at 1.0.
List<double> scalesFor(TestViewport viewport) {
  if (kFullMatrix) return kTextScales;
  if (viewport.size == kViewports[0].size) return const [2.0];
  if (viewport.size == kViewports[1].size) return const [1.0, 1.5];
  if (viewport.size == kViewports[3].size) return const [1.5];
  return const [1.0];
}

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
  for (final viewport in activeViewports) {
    for (final scale in scalesFor(viewport)) {
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
