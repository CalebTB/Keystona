import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../services/providers/service_providers.dart';
import '../../../subscription/providers/subscription_provider.dart';
import '../../models/document.dart';
import '../../models/document_format.dart';
import '../../providers/documents_provider.dart';
import '../shared/docs_section_header.dart';
import 'detail_fact_card.dart';

/// "File": name, category, when it was added and how much storage is used.
class DocumentFileSection extends ConsumerWidget {
  const DocumentFileSection({super.key, required this.document});

  final Document document;

  /// "Encrypted · 13 of 25 used" for free accounts, "Encrypted · 13 stored"
  /// for Premium, and just "Encrypted" while the count is unknown.
  static String storageLabel({required int? count, required bool isPremium}) {
    if (count == null) return 'Encrypted';
    return isPremium
        ? 'Encrypted · $count stored'
        : 'Encrypted · $count of $kFreeDocumentLimit used';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aurora;
    final isPremium = ref.watch(isPremiumProvider);
    final count = ref.watch(documentQuotaCountProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DocsSectionHeader(title: 'File'),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        DetailFactCard(
          facts: [
            DetailFact('Name', DocumentFormat.fileName(document.filePath)),
            if (document.category != null)
              DetailFact('Category', document.category!.name),
            DetailFact('Added', DocumentFormat.date(document.createdAt)),
            DetailFact(
              'Storage',
              storageLabel(count: count, isPremium: isPremium),
            ),
          ],
        ),
      ],
    );
  }
}
