import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/widgets/status_badge.dart';
import 'package:keystona/features/documents/screens/document_detail_screen.dart';
import 'package:keystona/features/documents/widgets/detail/document_coverage_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/responsive_harness.dart';
import '../detail_search/detail_search_support.dart';

const DocumentDetailScreen _screen = DocumentDetailScreen(documentId: 'doc-1');

/// A document right after a renewal: same row, the end date moved far out.
DocumentsStore _renewed() => DocumentsStore(
  fixtureDocument(
    name: 'Homeowners insurance policy',
    expiration: daysFromNow(400),
    notes: 'Paper copy is in the blue folder.',
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testResponsive(
    'renewed detail',
    () => _screen,
    wrap: (app) => scopeWrap(detailOverrides(documents: _renewed()), app),
  );

  testWidgets('a renewed document reads as active, with its coverage', (
    tester,
  ) async {
    await openScreen(tester, _screen, detailOverrides(documents: _renewed()));
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.byType(DocumentCoverageCard), findsOneWidget);
    expect(find.textContaining('Covered until'), findsOneWidget);
    expect(find.textContaining('EXPIRED'), findsNothing);
    expect(find.textContaining('LEFT'), findsWidgets);
  });

  testWidgets('the status badge sits beside the category, above the title', (
    tester,
  ) async {
    await openScreen(tester, _screen, detailOverrides(documents: _renewed()));
    final badge = tester.getRect(find.byType(StatusBadge));
    final category = tester.getRect(find.text('WARRANTIES & MANUALS'));
    final title = tester.getRect(find.text('Homeowners insurance policy'));
    final sameRow = badge.left > category.right;
    final nextRow = badge.top >= category.bottom - 1;
    expect(sameRow || nextRow, isTrue);
    if (nextRow) expect(badge.left, closeTo(category.left, 0.5));
    expect(title.top, greaterThan(badge.bottom));
  });
}
