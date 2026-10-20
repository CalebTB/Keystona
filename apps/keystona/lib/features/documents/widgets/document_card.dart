import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/aurora/aurora_card.dart';
import '../docs_copy.dart';
import '../models/document.dart';
import 'document_row.dart';

/// A bordered card for one [Document] in a result list. Tapping opens the
/// document detail route.
class DocumentCard extends StatelessWidget {
  const DocumentCard({super.key, required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    return AuroraCard(
      padding: EdgeInsets.zero,
      child: DocumentRow(
        name: document.name,
        meta: DocsCopy.rowMeta(document.category?.name, document.createdAt),
        expirationDate: document.expirationDate,
        onTap: () => context.push(
          AppRoutes.documentDetail.replaceFirst(':documentId', document.id),
        ),
      ),
    );
  }
}
