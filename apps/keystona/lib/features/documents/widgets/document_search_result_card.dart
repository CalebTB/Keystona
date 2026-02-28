import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/upgrade_sheet.dart';
import '../../../services/providers/service_providers.dart';
import '../models/document.dart';
import 'document_card.dart';

/// A search result card that wraps [DocumentCard] and optionally displays
/// an OCR text snippet below it (premium users only).
///
/// For free users, the PRO badge is shown on the search bar — this card
/// does not gate navigation. If the matched result comes from an OCR snippet
/// and the user is on the free tier, tapping the snippet row shows the
/// [UpgradeSheet].
class DocumentSearchResultCard extends ConsumerWidget {
  const DocumentSearchResultCard({
    super.key,
    required this.document,
    this.snippet,
  });

  final Document document;

  /// Highlighted OCR snippet from `ts_headline`. Non-null only for premium
  /// full-text search results. The RPC marks matched terms with `**...**`.
  final String? snippet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final hasSnippet = snippet != null && snippet!.isNotEmpty;

    if (!hasSnippet) {
      return DocumentCard(document: document);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocumentCard(document: document),
        if (isPremium)
          _SnippetRow(snippet: snippet!)
        else
          _LockedSnippetRow(
            onTap: () => UpgradeSheet.show(
              context,
              feature: 'full-text document search',
            ),
          ),
      ],
    );
  }
}

// ── Snippet row (premium) ─────────────────────────────────────────────────────

/// Displays the OCR text snippet beneath the document card for premium users.
/// `**term**` markers from `ts_headline` are stripped for plain display.
class _SnippetRow extends StatelessWidget {
  const _SnippetRow({required this.snippet});

  final String snippet;

  @override
  Widget build(BuildContext context) {
    // Strip **...** highlight markers from ts_headline output.
    final plain = snippet.replaceAll('**', '');

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppSizes.radiusMd),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        plain,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Locked snippet row (free tier) ───────────────────────────────────────────

/// Placeholder shown to free users when a document matches via OCR search.
/// Tapping shows the [UpgradeSheet].
class _LockedSnippetRow extends StatelessWidget {
  const _LockedSnippetRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.goldAccent.withAlpha(15),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppSizes.radiusMd),
          ),
          border: Border.all(color: AppColors.goldAccent.withAlpha(80)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.star_rounded,
              color: AppColors.goldAccent,
              size: AppSizes.iconSm,
            ),
            const SizedBox(width: AppSizes.xs),
            Expanded(
              child: Text(
                'Unlock document content search with Premium',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.goldAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.goldAccent,
              size: AppSizes.iconSm,
            ),
          ],
        ),
      ),
    );
  }
}
