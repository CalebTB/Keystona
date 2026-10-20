import 'package:flutter/painting.dart';

/// Tokens for the Tasks data wiring: the pieces the kit draws that the
/// earlier Tasks token files had no room for (the four-tile spec row, the
/// notes rule, the skipped bar). Values are logical px at the 390 pt
/// reference width; widgets read sizes through `context.aurora`.
abstract final class AuroraTasksWire {
  /// Spec tiles (Time / Level / Who / Cost) per row at regular text size.
  static const int specColumns = 4;

  /// Cobalt rule at the left of "Your notes" (kit: cobalt at 35%).
  static const Color notesRule = Color(0x592540D8);

  /// Distance between the diagonal lines of a skipped bar's hatch, and the
  /// line width (kit: 4 px clear, 1 px line).
  static const double hatchSpacing = 5;
  static const double hatchStroke = 1;
}
