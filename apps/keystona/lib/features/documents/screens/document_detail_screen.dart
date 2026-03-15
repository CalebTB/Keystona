import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../services/supabase_service.dart';
import '../models/document.dart';
import '../providers/document_detail_provider.dart';
import '../providers/document_links_provider.dart';
import '../widgets/document_detail_skeleton.dart';
import '../widgets/edit_metadata_sheet.dart';
import '../widgets/expiration_badge.dart';

/// Full document detail screen with in-app preview, metadata, and actions.
///
/// Route: `/documents/:documentId`
///
/// Adaptive layout:
/// - iOS: [CupertinoPageScaffold] with [CupertinoNavigationBar]
/// - Android: [Scaffold] with [AppBar]
class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS
        ? _IOSDetailLayout(documentId: documentId)
        : _AndroidDetailLayout(documentId: documentId);
  }
}

// ── iOS layout ────────────────────────────────────────────────────────────────

class _IOSDetailLayout extends ConsumerWidget {
  const _IOSDetailLayout({required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(documentDetailProvider(documentId));

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: 'Documents',
        middle: detailState.maybeWhen(
          data: (doc) => Text(doc.name, overflow: TextOverflow.ellipsis),
          orElse: () => const Text('Document'),
        ),
        trailing: detailState.maybeWhen(
          data: (doc) => CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => EditMetadataSheet.show(context, doc),
            child: const Text('Edit'),
          ),
          orElse: () => null,
        ),
      ),
      child: detailState.when(
        loading: () => const DocumentDetailSkeleton(),
        error: (e, _) => ErrorView(
          message: "Couldn't load document.",
          onRetry: () => ref.invalidate(documentDetailProvider(documentId)),
        ),
        data: (doc) => _DetailBody(document: doc, documentId: documentId),
      ),
    );
  }
}

// ── Android layout ────────────────────────────────────────────────────────────

class _AndroidDetailLayout extends ConsumerWidget {
  const _AndroidDetailLayout({required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(documentDetailProvider(documentId));

    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        title: detailState.maybeWhen(
          data: (doc) => Text(doc.name, style: AppTextStyles.h4),
          orElse: () => const Text('Document'),
        ),
        backgroundColor: AppColors.warmOffWhite,
        scrolledUnderElevation: 0,
        elevation: 0,
        actions: [
          if (detailState.hasValue)
            TextButton(
              onPressed: () =>
                  EditMetadataSheet.show(context, detailState.value!),
              child: Text(
                'Edit',
                style: AppTextStyles.button.copyWith(color: AppColors.deepNavy),
              ),
            ),
        ],
      ),
      body: detailState.when(
        loading: () => const DocumentDetailSkeleton(),
        error: (e, _) => ErrorView(
          message: "Couldn't load document.",
          onRetry: () => ref.invalidate(documentDetailProvider(documentId)),
        ),
        data: (doc) => _DetailBody(document: doc, documentId: documentId),
      ),
    );
  }
}

// ── Shared detail body ────────────────────────────────────────────────────────

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.document, required this.documentId});

  final Document document;
  final String documentId;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  bool _deletePending = false;
  Timer? _deleteTimer;

  @override
  void dispose() {
    _deleteTimer?.cancel();
    super.dispose();
  }

  Future<void> _onShare() async {
    try {
      final url = await ref
          .read(documentDetailProvider(widget.documentId).notifier)
          .getSignedUrl();
      if (url == null) {
        if (mounted) {
          SnackbarService.showError(context, "Couldn't generate share link.");
        }
        return;
      }
      await SharePlus.instance.share(
        ShareParams(uri: Uri.parse(url), text: widget.document.name),
      );
    } catch (_) {
      if (mounted) SnackbarService.showError(context, "Couldn't share document.");
    }
  }

  Future<void> _onDownload() async {
    try {
      final url = await ref
          .read(documentDetailProvider(widget.documentId).notifier)
          .getSignedUrl();
      if (url == null) {
        if (mounted) {
          SnackbarService.showError(context, "Couldn't generate download link.");
        }
        return;
      }
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) SnackbarService.showError(context, "Couldn't open download.");
    }
  }

  Future<void> _onDelete() async {
    await ConfirmDialog.show(
      context,
      title: 'Delete document?',
      message:
          'The document will be moved to trash. You can undo this within 5 seconds.',
      confirmLabel: 'Delete',
      onConfirm: _commitDelete,
    );
  }

  Future<void> _commitDelete() async {
    if (_deletePending) return;
    setState(() => _deletePending = true);

    try {
      await ref
          .read(documentDetailProvider(widget.documentId).notifier)
          .softDelete();
    } catch (_) {
      if (mounted) {
        setState(() => _deletePending = false);
        SnackbarService.showError(context, "Couldn't delete document. Try again.");
      }
      return;
    }

    if (!mounted) return;

    // Show 5-second undo snackbar. If dismissed without undo, pop the screen.
    final controller = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Document moved to trash.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textInverse),
        ),
        backgroundColor: AppColors.gray800,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.goldAccent,
          onPressed: _undoDelete,
        ),
      ),
    );

    // Navigate back when the snackbar closes and undo was not pressed.
    _deleteTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _deletePending) {
        controller.close();
        context.pop();
      }
    });
  }

  Future<void> _undoDelete() async {
    _deleteTimer?.cancel();
    _deleteTimer = null;

    try {
      await ref
          .read(documentDetailProvider(widget.documentId).notifier)
          .restore();
      if (mounted) {
        setState(() => _deletePending = false);
        SnackbarService.showSuccess(context, 'Document restored.');
      }
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(context, "Couldn't restore document.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-watch so the UI updates after edit metadata saves.
    final doc = ref
            .watch(documentDetailProvider(widget.documentId))
            .value ??
        widget.document;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _DocumentPreview(document: doc),
          ),
          SliverPadding(
            padding: AppPadding.screen,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSizes.lg),
                _ActionRow(
                  onShare: _onShare,
                  onDownload: _onDownload,
                  onDelete: _deletePending ? null : _onDelete,
                ),
                const SizedBox(height: AppSizes.lg),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: AppSizes.md),
                _MetadataSection(document: doc),
                if (doc.linkedSystemId != null || doc.linkedApplianceId != null) ...[
                  const SizedBox(height: AppSizes.md),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: AppSizes.md),
                  _LinkedChip(document: doc),
                ],
                _LinkedItemsSection(documentId: widget.documentId),
                const SizedBox(height: AppSizes.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Document preview ──────────────────────────────────────────────────────────

/// Shows the document file inline.
///
/// - `application/pdf` → [PdfView] with page navigation + pinch-to-zoom
/// - `image/*`         → [PhotoView] with pinch-to-zoom
/// - Other MIME types  → generic file icon placeholder
class _DocumentPreview extends StatefulWidget {
  const _DocumentPreview({required this.document});

  final Document document;

  @override
  State<_DocumentPreview> createState() => _DocumentPreviewState();
}

class _DocumentPreviewState extends State<_DocumentPreview> {
  bool get _isPdf {
    return (widget.document.mimeType ?? '').contains('pdf');
  }

  bool get _isImage {
    return (widget.document.mimeType ?? '').startsWith('image/');
  }

  @override
  Widget build(BuildContext context) {
    if (_isPdf) return _PdfPreview(filePath: widget.document.filePath);
    if (_isImage) return _ImagePreview(filePath: widget.document.filePath);

    return Container(
      width: double.infinity,
      height: 240,
      color: AppColors.gray100,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_outlined,
                size: AppSizes.iconXl, color: AppColors.gray400),
            const SizedBox(height: AppSizes.sm),
            Text(
              widget.document.mimeType ?? 'File',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfPreview extends StatefulWidget {
  const _PdfPreview({required this.filePath});

  final String filePath;

  @override
  State<_PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<_PdfPreview> {
  late final PdfController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfController(
      document: PdfDocument.openData(
        // Download raw bytes via the authenticated Supabase client. This
        // avoids a separate HTTP call and respects RLS-scoped storage policies.
        SupabaseService.client.storage
            .from('documents')
            .download(widget.filePath),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 480,
      child: PdfView(
        controller: _controller,
        scrollDirection: Axis.vertical,
        builders: PdfViewBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) => const Center(
            child: CircularProgressIndicator(color: AppColors.deepNavy),
          ),
          pageLoaderBuilder: (_) => const Center(
            child: CircularProgressIndicator(color: AppColors.deepNavy),
          ),
          errorBuilder: (_, error) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: AppSizes.iconLg, color: AppColors.error),
                const SizedBox(height: AppSizes.sm),
                Text('PDF preview unavailable',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatefulWidget {
  const _ImagePreview({required this.filePath});

  final String filePath;

  @override
  State<_ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<_ImagePreview> {
  String? _signedUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSignedUrl();
  }

  Future<void> _loadSignedUrl() async {
    try {
      final url = await SupabaseService.client.storage
          .from('documents')
          .createSignedUrl(widget.filePath, 3600);
      if (mounted) setState(() { _signedUrl = url; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        width: double.infinity,
        height: 320,
        color: AppColors.gray200,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.deepNavy),
        ),
      );
    }

    if (_signedUrl == null) {
      return Container(
        width: double.infinity,
        height: 320,
        color: AppColors.gray100,
        child: Center(
          child: Text(
            'Preview unavailable',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return SizedBox(
      height: 320,
      child: PhotoView(
        imageProvider: NetworkImage(_signedUrl!),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4,
        backgroundDecoration: const BoxDecoration(color: AppColors.gray900),
        loadingBuilder: (_, event) => Center(
          child: CircularProgressIndicator(
            color: AppColors.deepNavy,
            value: event == null
                ? null
                : event.cumulativeBytesLoaded /
                    (event.expectedTotalBytes ?? 1),
          ),
        ),
      ),
    );
  }
}

// ── Action row ────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.onShare,
    required this.onDownload,
    required this.onDelete,
  });

  final VoidCallback onShare;
  final VoidCallback onDownload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: onShare,
        ),
        const SizedBox(width: AppSizes.sm),
        _ActionButton(
          icon: Icons.download_outlined,
          label: 'Download',
          onTap: onDownload,
        ),
        const SizedBox(width: AppSizes.sm),
        _ActionButton(
          icon: Icons.delete_outline,
          label: 'Delete',
          onTap: onDelete,
          destructive: true,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final color = isDisabled
        ? AppColors.textDisabled
        : (destructive ? AppColors.error : AppColors.deepNavy);
    final bg = isDisabled
        ? AppColors.gray100
        : (destructive ? AppColors.errorLight : AppColors.surfaceVariant);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.iconMd, color: color),
              const SizedBox(height: AppSizes.xs),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Metadata section ──────────────────────────────────────────────────────────

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final uploadedDate = DateFormat('MMM d, yyyy').format(document.createdAt);
    final updatedDate = DateFormat('MMM d, yyyy').format(document.updatedAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Details', style: AppTextStyles.h4),
        const SizedBox(height: AppSizes.md),

        _MetadataRow(label: 'Category', value: document.category?.name ?? '—'),
        _MetadataRow(label: 'Type', value: document.type?.name ?? '—'),
        _MetadataRow(label: 'Uploaded', value: uploadedDate),
        _MetadataRow(label: 'Updated', value: updatedDate),
        if (document.fileSizeBytes != null)
          _MetadataRow(
            label: 'Size',
            value: _formatFileSize(document.fileSizeBytes!),
          ),
        if (document.pageCount != null)
          _MetadataRow(label: 'Pages', value: '${document.pageCount}'),

        // Expiration row with badge.
        if (document.expirationDate != null) ...[
          const SizedBox(height: AppSizes.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expires',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              ExpirationBadge(
                expirationDate: document.expirationDate!,
                large: true,
              ),
            ],
          ),
        ],

        // Notes.
        if (document.notes != null && document.notes!.isNotEmpty) ...[
          const SizedBox(height: AppSizes.md),
          Text(
            'Notes',
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(document.notes!, style: AppTextStyles.bodyMedium),
        ],
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSizes.md),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reverse links section ─────────────────────────────────────────────────────

/// Shows all entities across the app that reference this document.
///
/// Queries [documentLinksProvider] and hides itself when the result is empty
/// or still loading — no skeleton or error state is surfaced here since it is
/// supplemental content below the primary metadata.
class _LinkedItemsSection extends ConsumerWidget {
  const _LinkedItemsSection({required this.documentId});

  final String documentId;

  static IconData _iconFor(String type) {
    return switch (type) {
      'project' => Icons.folder_outlined,
      'appliance' => Icons.kitchen_outlined,
      _ => Icons.settings_outlined,
    };
  }

  static String _typeLabel(String type) {
    return switch (type) {
      'project' => 'Project',
      'appliance' => 'Appliance',
      _ => 'System',
    };
  }

  void _navigate(BuildContext context, DocumentLinkEntry entry) {
    final path = switch (entry.type) {
      'project' =>
        AppRoutes.projectDetail.replaceFirst(':projectId', entry.id),
      'appliance' =>
        AppRoutes.homeApplianceDetail.replaceFirst(':applianceId', entry.id),
      _ => AppRoutes.homeSystemDetail.replaceFirst(':systemId', entry.id),
    };
    context.push(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksState = ref.watch(documentLinksProvider(documentId));

    // Only render when we have at least one link — hide during loading and
    // on empty results so the section never adds dead whitespace.
    return linksState.maybeWhen(
      data: (links) {
        if (links.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.md),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppSizes.md),
            Text('Used In', style: AppTextStyles.h4),
            const SizedBox(height: AppSizes.sm),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: links.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, index) {
                final entry = links[index];
                return _LinkedItemRow(
                  entry: entry,
                  icon: _iconFor(entry.type),
                  typeLabel: entry.subtitle ?? _typeLabel(entry.type),
                  onTap: () => _navigate(context, entry),
                );
              },
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _LinkedItemRow extends StatelessWidget {
  const _LinkedItemRow({
    required this.entry,
    required this.icon,
    required this.typeLabel,
    required this.onTap,
  });

  final DocumentLinkEntry entry;
  final IconData icon;
  final String typeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.deepNavy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: AppSizes.iconSm, color: AppColors.deepNavy),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    typeLabel,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: AppSizes.iconSm,
              color: AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Linked system / appliance chip ────────────────────────────────────────────

class _LinkedChip extends StatelessWidget {
  const _LinkedChip({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final isSystem = document.linkedSystemId != null;
    final id = document.linkedSystemId ?? document.linkedApplianceId ?? '';
    final label = isSystem ? 'Linked System' : 'Linked Appliance';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Linked To',
          style: AppTextStyles.labelMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSizes.xs),
        GestureDetector(
          onTap: () {
            final path = isSystem
                ? AppRoutes.homeSystemDetail.replaceFirst(':systemId', id)
                : AppRoutes.homeApplianceDetail
                    .replaceFirst(':applianceId', id);
            context.push(path);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(color: AppColors.info),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSystem ? Icons.home_outlined : Icons.kitchen_outlined,
                  size: AppSizes.iconSm,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppSizes.xs),
                Text(
                  label,
                  style:
                      AppTextStyles.labelMedium.copyWith(color: AppColors.info),
                ),
                const SizedBox(width: AppSizes.xs),
                const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.info),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
