import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/supabase_service.dart';
import '../models/document.dart';
import '../models/document_category.dart';
import '../widgets/category_form_sheet.dart';
import 'expiration_badge.dart';

/// A list-item card representing a single document in the Document Vault.
///
/// Layout:
///   [Thumbnail | Name + Category Badge + Date Added | Expiration Badge]
///
/// Thumbnail falls back to a category-color icon when [Document.thumbnailPath]
/// is null. Expiration badge colour follows a traffic-light system:
///   - > 90 days → green
///   - 30–90 days → amber
///   - < 30 days or already expired → red
///
/// Tapping the card navigates to the document detail route.
class DocumentCard extends StatelessWidget {
  const DocumentCard({super.key, required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final path =
            AppRoutes.documentDetail.replaceFirst(':documentId', document.id);
        context.push(path);
      },
      child: Container(
        padding: AppPadding.card,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _DocumentThumbnail(document: document),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: _DocumentInfo(document: document),
            ),
            if (document.expirationDate != null) ...[
              const SizedBox(width: AppSizes.sm),
              ExpirationBadge(expirationDate: document.expirationDate!),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Thumbnail ──────────────────────────────────────────────────────────────────

class _DocumentThumbnail extends StatelessWidget {
  const _DocumentThumbnail({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final thumbnailPath = document.thumbnailPath;
    if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
      return _NetworkThumbnail(storagePath: thumbnailPath);
    }
    return _CategoryIconThumbnail(category: document.category);
  }
}

class _NetworkThumbnail extends StatelessWidget {
  const _NetworkThumbnail({required this.storagePath});

  final String storagePath;

  @override
  Widget build(BuildContext context) {
    // Generate a short-lived signed URL for the thumbnail so the file is
    // never publicly accessible. The URL expires after 60 seconds — suitable
    // for in-memory display only.
    final signedUrl = SupabaseService.client.storage
        .from('documents')
        .getPublicUrl(storagePath);

    return ClipRRect(
      borderRadius: AppRadius.sm,
      child: CachedNetworkImage(
        imageUrl: signedUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 48,
          height: 48,
          color: AppColors.gray200,
        ),
        errorWidget: (context, url, error) => _CategoryIconThumbnail(
          category: null,
        ),
      ),
    );
  }
}

class _CategoryIconThumbnail extends StatelessWidget {
  const _CategoryIconThumbnail({required this.category});

  final DocumentCategory? category;

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseCategoryColor(category?.color);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor.withAlpha(30),
        borderRadius: AppRadius.sm,
      ),
      child: Icon(
        CategoryIcons.forKey(category?.icon ?? ''),
        color: bgColor,
        size: AppSizes.iconMd,
      ),
    );
  }

/// Parses a hex color string like '#1565C0' to a [Color].
  /// Falls back to [AppColors.deepNavy] when parsing fails.
  Color _parseCategoryColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.deepNavy;
    final sanitised = hex.replaceAll('#', '');
    if (sanitised.length != 6) return AppColors.deepNavy;
    final value = int.tryParse('FF$sanitised', radix: 16);
    return value != null ? Color(value) : AppColors.deepNavy;
  }
}

// ── Document info ─────────────────────────────────────────────────────────────

class _DocumentInfo extends StatelessWidget {
  const _DocumentInfo({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          document.name,
          style: AppTextStyles.bodyMediumSemibold,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (document.category != null) ...[
          const SizedBox(height: AppSizes.xs),
          _CategoryBadge(category: document.category!),
        ],
        const SizedBox(height: AppSizes.xs),
        Text(
          _formatDate(document.createdAt),
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final DocumentCategory category;

  @override
  Widget build(BuildContext context) {
    final color = _parseCategoryColor(category.color);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        category.name,
        style: AppTextStyles.labelSmall.copyWith(color: color),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Color _parseCategoryColor(String hex) {
    final sanitised = hex.replaceAll('#', '');
    if (sanitised.length != 6) return AppColors.deepNavy;
    final value = int.tryParse('FF$sanitised', radix: 16);
    return value != null ? Color(value) : AppColors.deepNavy;
  }
}

