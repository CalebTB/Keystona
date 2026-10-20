import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/widgets/status_badge.dart';
import 'package:keystona/features/documents/docs_copy.dart';
import 'package:keystona/features/documents/screens/document_detail_screen.dart';
import 'package:keystona/features/documents/widgets/detail/document_coverage_card.dart';
import 'package:keystona/features/documents/widgets/detail/document_replaced_note.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/responsive_harness.dart';
import '../detail_search/detail_search_support.dart';

const DocumentDetailScreen _screen = DocumentDetailScreen(documentId: 'doc-1');

final DateTime _replacedOn = DateTime(2025, 10, 4);

DocumentsStore _replaced({String? by = 'new-1'}) => DocumentsStore(
  fixtureDocument(
    name: 'Previous homeowners policy',
    expiration: daysFromNow(9),
    metadata: {
      'replaced_at': '2025-10-04',
      'replaced_by': ?by,
    },
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('responsive', () {
    testResponsive(
      'replaced detail',
      () => _screen,
      wrap: (app) =>
          scopeWrap(detailOverrides(documents: _replaced()), app),
    );
  });

  testWidgets('a replaced document shows a quiet status, not urgency', (
    tester,
  ) async {
    await openScreen(
      tester,
      _screen,
      detailOverrides(documents: _replaced()),
    );

    expect(find.text(DocsCopy.replacedChip(_replacedOn).toUpperCase()),
        findsOneWidget);
    // No days-left chip and no coverage card.
    expect(find.textContaining('LEFT'), findsNothing);
    expect(find.text('EXPIRED'), findsNothing);
    expect(find.byType(DocumentCoverageCard), findsNothing);
    expect(find.text(DocsCopy.replacedNote), findsOneWidget);
    expect(find.text(DocsCopy.seeNewerCopy), findsOneWidget);
  });

  testWidgets('the note sits below the file preview and the badge beside '
      'the category', (tester) async {
    await openScreen(
      tester,
      _screen,
      detailOverrides(documents: _replaced()),
    );
    final badge = tester.getRect(find.byType(StatusBadge));
    final category = tester.getRect(find.text('WARRANTIES & MANUALS'));
    final title = tester.getRect(find.text('Previous homeowners policy'));
    final note = tester.getRect(find.byType(DocumentReplacedNote));

    // The eyebrow wraps: the badge follows the category on its row, or
    // starts the next row at the same left edge.
    final sameRow = badge.left > category.right;
    final nextRow = badge.top >= category.bottom - 1;
    expect(sameRow || nextRow, isTrue);
    if (nextRow) expect(badge.left, closeTo(category.left, 0.5));
    expect(title.top, greaterThan(badge.bottom));
    expect(note.top, greaterThan(title.bottom));
    final width = tester.view.physicalSize.width;
    expect(note.left, lessThan(width * 0.1));
    expect(width - note.right, closeTo(note.left, 0.5));
  });

  testWidgets('the link opens the newer document', (tester) async {
    await openScreen(
      tester,
      _screen,
      detailOverrides(documents: _replaced()),
    );
    await tester.tap(find.text(DocsCopy.seeNewerCopy));
    await tester.pump();
    await tester.pump(kPushTransition);
    expect(find.text('detail new-1'), findsOneWidget);
  });

  testWidgets('without a recorded newer copy there is no link', (tester) async {
    await openScreen(
      tester,
      _screen,
      detailOverrides(documents: _replaced(by: null)),
    );
    expect(find.text(DocsCopy.replacedNote), findsOneWidget);
    expect(find.text(DocsCopy.seeNewerCopy), findsNothing);
  });

  testWidgets('an unreplaced expired document still reads as expired', (
    tester,
  ) async {
    await openScreen(
      tester,
      _screen,
      detailOverrides(
        documents: DocumentsStore(fixtureDocument(expiration: daysFromNow(-5))),
      ),
    );
    expect(find.text('EXPIRED'), findsWidgets);
    expect(find.byType(DocumentCoverageCard), findsOneWidget);
    expect(find.byType(DocumentReplacedNote), findsNothing);
  });
}
