import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';

/// Empty state for the Document Vault list screen.
///
/// Copy is taken verbatim from Empty States Catalog §2.2. Do not modify
/// the headline or subtitle text without updating the catalog.
class DocumentEmptyState extends StatelessWidget {
  const DocumentEmptyState({super.key, required this.onAdd});

  /// Called when the user taps the "+ Add First Document" CTA.
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.folder_open_outlined,
      title: 'Your Document Vault is ready!',
      subtitle:
          'Most homeowners start by uploading their insurance policy — '
          'it only takes 30 seconds.',
      actionLabel: '+ Add First Document',
      onAction: onAdd,
    );
  }
}
