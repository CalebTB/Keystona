import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/theme/aurora_docs_c.dart';
import 'package:keystona/core/theme/aurora_spacing.dart';
import 'package:keystona/features/documents/widgets/detail/detail_fact_card.dart';
import 'package:keystona/features/documents/widgets/detail/document_detail_top_bar.dart';
import 'package:keystona/features/documents/widgets/detail/document_facts_section.dart';
import 'package:keystona/features/documents/widgets/detail/document_preview_card.dart';
import 'package:keystona/features/documents/widgets/shared/docs_section_header.dart';
import 'package:keystona/features/documents/widgets/detail/document_tags_row.dart';

import 'detail_search_support.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child))),
  );
}

void main() {
  testWidgets('Share and Edit sit at the right edge of the top bar', (t) async {
    await _pump(
      t,
      DocumentDetailTopBar(onBack: () {}, onShare: () {}, onEdit: () {}),
    );
    final bar = t.getRect(find.byType(DocumentDetailTopBar));
    final edit = t.getRect(find.text('Edit'));
    final back = t.getRect(find.text('Docs'));
    expect(back.left, lessThan(bar.left + 60));
    // Edit's tap target ends at the bar's right edge.
    expect(bar.right - edit.right, lessThan(24));
  });

  testWidgets('fact values fill the row, right-aligned, not a half-width box',
      (t) async {
    await _pump(
      t,
      const DetailFactCard(
        facts: [DetailFact('Name', 'a-very-long-document-name-that-wraps.jpg')],
      ),
    );
    final card = t.getRect(find.byType(DetailFactCard));
    final value = t.getRect(find.textContaining('a-very-long'));
    // Right edge of the value is at the card's right padding, and the value
    // gets well over half the card's width.
    expect(card.right - value.right, lessThan(24));
    expect(value.width, greaterThan(card.width * 0.5));
  });

  test('tags are chips, not a fact row', () {
    final doc = fixtureDocument(metadata: {
      'tags': ['test', '#cargo'],
      'serial': '2103A47719',
    });
    expect(
      DocumentFactsSection.factsOf(doc).map((f) => f.label),
      ['Serial'],
    );
    expect(DocumentTagsRow.tagsOf(doc), ['test', 'cargo']);
  });

  testWidgets('tag chips render with a leading #', (t) async {
    await _pump(t, const DocumentTagsRow(tags: ['furnace', '2021 install']));
    expect(find.text('#furnace'), findsOneWidget);
    expect(find.text('#2021 install'), findsOneWidget);
  });

  testWidgets('Open pill sits at the right edge of the preview frame', (t) async {
    await _pump(
      t,
      ProviderScope(
        child: DocumentPreviewCard(
          document: fixtureDocument().copyWith(thumbnailPath: null, pageCount: 1),
          onOpen: () {},
        ),
      ),
    );
    final frame = t.getRect(find.byType(DocumentPreviewCard));
    final open = t.getRect(find.text('Open'));
    final tag = t.getRect(find.textContaining('PAGE 1 OF'));
    // The pill's edge is the corner inset from the frame; the label sits one
    // pill padding further in. (Regular width: tokens are unscaled.)
    expect(
      frame.right - open.right,
      closeTo(
        AuroraDocsCSizes.previewCornerInset + AuroraDocsCSizes.openPillPadH,
        1,
      ),
    );
    expect(
      tag.left - frame.left,
      lessThan(AuroraDocsCSizes.previewCornerInset + AuroraSpacing.space5),
    );
  });

  testWidgets('section header trailing text sits at the right edge', (t) async {
    await _pump(
      t,
      const DocsSectionHeader(title: 'What it says', trailing: Text('READ BY SMART SCAN')),
    );
    final row = t.getRect(find.byType(DocsSectionHeader));
    final trailing = t.getRect(find.text('READ BY SMART SCAN'));
    expect(row.right - trailing.right, lessThan(4));
  });
}
