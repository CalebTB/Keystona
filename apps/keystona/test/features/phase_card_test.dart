import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/projects/models/project_phase.dart';
import 'package:keystona/features/projects/widgets/phase_card.dart';

/// Regression test for the RenderFlex overflow in `_DateInfo`.
///
/// The row renders the planned date plus a health label ("· 3 days overdue").
/// Both were unconstrained Text widgets inside a `mainAxisSize.min` Row, so a
/// long label overflowed the card's width budget instead of truncating.
ProjectPhase _phase({DateTime? plannedEnd, String name = 'Rough-in'}) {
  final now = DateTime(2026, 10, 4);
  return ProjectPhase(
    id: 'p1',
    projectId: 'proj1',
    userId: 'u1',
    name: name,
    plannedEndDate: plannedEnd,
    createdAt: now,
    updatedAt: now,
  );
}

/// Real card widths: a phase card is full-width minus 16pt screen padding
/// each side, so ~343pt on an iPhone SE and ~358pt on an iPhone 16.
///
/// Both Texts in the date row are Flexible, so the layout holds well below
/// the narrowest shipping iPhone (343pt). 260pt is used as a stress bound.
const _seWidth = 343.0;
const _phoneWidth = 358.0;
const _stressWidth = 260.0;

Future<void> _pumpCard(
  WidgetTester tester,
  ProjectPhase phase, {
  double width = _phoneWidth,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: PhaseCard(phase: phase, onTap: () {}),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('PhaseCard date row', () {
    testWidgets('does not overflow with a long overdue label', (tester) async {
      // Well in the past -> "N days overdue", the longest label variant.
      await _pumpCard(
        tester,
        _phase(plannedEnd: DateTime(2025, 1, 15)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow on an iPhone SE width', (tester) async {
      await _pumpCard(
        tester,
        _phase(plannedEnd: DateTime(2025, 1, 15), name: 'Rough-in'),
        width: _seWidth,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow for due-soon or no-date phases',
        (tester) async {
      for (final end in [
        DateTime.now().add(const Duration(days: 3)), // "Due in 3 days"
        DateTime.now(), // "Due today"
        DateTime.now().add(const Duration(days: 1)), // "Due tomorrow"
        null, // no label at all
      ]) {
        await _pumpCard(tester, _phase(plannedEnd: end), width: _seWidth);
        expect(tester.takeException(), isNull, reason: 'plannedEnd: $end');
      }
    });

    testWidgets('renders a long phase name without overflowing',
        (tester) async {
      await _pumpCard(
        tester,
        _phase(
          plannedEnd: DateTime(2025, 1, 15),
          name: 'Electrical rough-in and panel upgrade inspection',
        ),
        width: _stressWidth,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
