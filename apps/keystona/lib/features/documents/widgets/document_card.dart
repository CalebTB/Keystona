import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AuroraRadius.md,
        onTap: () {
          final path =
              AppRoutes.documentDetail.replaceFirst(':documentId', document.id);
          context.push(path);
        },
        child: Container(
          padding: const EdgeInsets.all(AuroraSpacing.space6),
          decoration: BoxDecoration(
            color: AuroraColors.paper,
            borderRadius: AuroraRadius.md,
            border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D071238),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _DocumentThumbnail(document: document),
              const SizedBox(width: AuroraSpacing.space5),
              Expanded(
                child: _DocumentInfo(document: document),
              ),
              if (document.expirationDate != null) ...[
                const SizedBox(width: AuroraSpacing.space3),
                ExpirationBadge(expirationDate: document.expirationDate!),
              ],
            ],
          ),
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
    final signedUrl = SupabaseService.client.storage
        .from('documents')
        .getPublicUrl(storagePath);

    return ClipRRect(
      borderRadius: AuroraRadius.sm,
      child: CachedNetworkImage(
        imageUrl: signedUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 48,
          height: 48,
          color: AuroraColors.butter,
        ),
        errorWidget: (context, url, error) => const _CategoryIconThumbnail(
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
        borderRadius: AuroraRadius.sm,
      ),
      child: Icon(
        CategoryIcons.forKey(category?.icon ?? ''),
        color: bgColor,
        size: 20,
      ),
    );
  }

  /// Parses a hex color string like '#1565C0' to a [Color].
  /// Falls back to [AuroraColors.coral] when parsing fails.
  Color _parseCategoryColor(String? hex) {
    if (hex == null || hex.isEmpty) return AuroraColors.coral;
    final sanitised = hex.replaceAll('#', '');
    if (sanitised.length != 6) return AuroraColors.coral;
    final value = int.tryParse('FF$sanitised', radix: 16);
    return value != null ? Color(value) : AuroraColors.coral;
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
          style: AuroraType.body.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (document.category != null) ...[
          const SizedBox(height: AuroraSpacing.space1),
          _CategoryBadge(category: document.category!),
        ],
        const SizedBox(height: AuroraSpacing.space1),
        Text(
          _formatDate(document.createdAt),
          style: AuroraType.bodySm,
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
        horizontal: AuroraSpacing.space3,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        category.name.toUpperCase(),
        style: AuroraType.labelSm.copyWith(color: color),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Color _parseCategoryColor(String hex) {
    final sanitised = hex.replaceAll('#', '');
    if (sanitised.length != 6) return AuroraColors.coral;
    final value = int.tryParse('FF$sanitised', radix: 16);
    return value != null ? Color(value) : AuroraColors.coral;
  }
}
