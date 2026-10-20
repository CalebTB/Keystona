import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/responsive_harness.dart';

/// Horizontal screen padding the harness gives a widget (the screen inset).
const double kPad = 16;

/// A scrolling page holding [child], padded like a screen.
Widget page(Widget child) => Scaffold(
  body: SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: kPad),
    child: child,
  ),
);

/// Pumps [child] on the reference phone (390 wide) at [textScale].
Future<void> pumpPhone(
  WidgetTester tester,
  Widget child, {
  double textScale = 1,
  bool padded = true,
}) => pumpScreen(
  tester,
  () => padded ? page(child) : Scaffold(body: SingleChildScrollView(child: child)),
  viewport: kViewports[1],
  textScale: textScale,
);

/// [testResponsive] for a widget inside a padded scrolling page.
void testWidgetResponsive(
  String description,
  Widget Function() child, {
  bool padded = true,
}) => testResponsive(
  description,
  () => padded
      ? page(child())
      : Scaffold(body: SingleChildScrollView(child: child())),
);

/// The right edge of the page content on the reference phone.
double get contentRight => kViewports[1].size.width - kPad;
