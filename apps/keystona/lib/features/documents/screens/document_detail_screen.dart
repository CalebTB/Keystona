import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../models/document_category.dart';
import '../providers/document_detail_provider.dart';
import '../providers/document_links_provider.dart';
import '../widgets/document_detail_skeleton.dart';
import '../widgets/edit_metadata_sheet.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _catColor(DocumentCategory? category) {
  final hex = category?.color;
  if (hex == null || hex.isEmpty) return AppColors.slate;
  try {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  } catch (_) {
    return AppColors.slate;
  }
}

String _extFromMime(String? mime) {
  if (mime == null || mime.isEmpty) return 'FILE';
  if (mime.contains('pdf')) return 'PDF';
  if (mime.contains('jpeg') || mime.contains('jpg')) return 'JPG';
  if (mime.contains('png')) return 'PNG';
  if (mime.contains('heic')) return 'HEIC';
  if (mime.contains('gif')) return 'GIF';
  if (mime.contains('webp')) return 'WEBP';
  final ext = mime.split('/').last.toUpperCase();
  return ext.length > 4 ? ext.substring(0, 4) : ext;
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

/// Card-stack document detail screen.
///
/// Route: `/documents/:documentId`
class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(documentDetailProvider(documentId));
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      body: detailState.when(
        loading: () => const DocumentDetailSkeleton(),
        error: (e, _) => SafeArea(
          child: Column(
            children: [
              _BackButton(onTap: () => context.pop()),
              Expanded(
                child: ErrorView(
                  message: "Couldn't load document.",
                  onRetry: () =>
                      ref.invalidate(documentDetailProvider(documentId)),
                ),
              ),
            ],
          ),
        ),
        data: (doc) => _DetailBody(document: doc, documentId: documentId),
      ),
    );
  }
}

// ─── Back button (error state) ────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, 12, 0, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.chevron_back,
                color: AppColors.accent, size: 20),
            const SizedBox(width: 2),
            Text(
              'Documents',
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.accent, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Body ──────────────────────────────────────────────────────────────

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
        if (mounted) SnackbarService.showError(context, "Couldn't generate share link.");
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
        if (mounted) SnackbarService.showError(context, "Couldn't generate download link.");
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
      message: 'The document will be moved to trash. You can undo this within 5 seconds.',
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
      if (mounted) SnackbarService.showError(context, "Couldn't restore document.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = ref.watch(documentDetailProvider(widget.documentId)).value ??
        widget.document;
    final catColor = _catColor(doc.category);
    final daysLeft = doc.expirationDate
        ?.difference(DateTime.now())
        .inDays;
    final showExpiryCard = daysLeft != null && daysLeft < 90;
    final hasNotes = doc.notes != null && doc.notes!.isNotEmpty;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: _NavRow(documentId: widget.documentId, document: doc),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenPadding,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 14),
                  _PreviewCard(document: doc, catColor: catColor),
                  const SizedBox(height: 16),
                  _TitleArea(
                    document: doc,
                    catColor: catColor,
                    daysLeft: daysLeft,
                  ),
                  if (showExpiryCard) ...[
                    const SizedBox(height: 12),
                    _ExpiryCountdownCard(daysLeft: daysLeft),
                  ],
                  const SizedBox(height: AppSizes.md),
                  _DetailsCard(document: doc),
                  const SizedBox(height: AppSizes.md),
                  _LinkedToCard(document: doc),
                  _UsedInCard(documentId: widget.documentId),
                  if (hasNotes) ...[
                    const SizedBox(height: AppSizes.md),
                    _NotesCard(document: doc),
                  ],
                  const SizedBox(height: AppSizes.md),
                  _FileInfoCard(document: doc),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _BottomActionBar(
            onShare: _onShare,
            onDownload: _onDownload,
            onDelete: _deletePending ? null : _onDelete,
          ),
        ),
      ],
    );
  }
}

// ─── Nav Row ──────────────────────────────────────────────────────────────────

class _NavRow extends ConsumerWidget {
  const _NavRow({required this.documentId, required this.document});

  final String documentId;
  final Document document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding, 8, AppSizes.screenPadding, 0,
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.chevron_back,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 2),
                Text(
                  'Documents',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _NavIconButton(
            icon: Icons.edit_outlined,
            onTap: () => EditMetadataSheet.show(context, document),
          ),
          const SizedBox(width: 6),
          _NavIconButton(
            icon: Icons.more_horiz,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepNavy.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}

// ─── Preview Card ─────────────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.document, required this.catColor});

  final Document document;
  final Color catColor;

  @override
  Widget build(BuildContext context) {
    final ext = _extFromMime(document.mimeType);
    final dimColor = catColor.withValues(alpha: 0.07);
    final borderColor = catColor.withValues(alpha: 0.12);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => _FullscreenPreview(document: document),
        ),
      ),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepNavy.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(AppSizes.radiusLg - 1.5),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.center,
                      colors: [dimColor, AppColors.surface],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 80,
                      decoration: BoxDecoration(
                        color: dimColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.insert_drive_file_outlined,
                              size: 28, color: catColor),
                          const SizedBox(height: 4),
                          Text(
                            ext,
                            style: AppTextStyles.monoTiny.copyWith(
                              color: catColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      document.pageCount != null
                          ? '${document.pageCount} page${document.pageCount == 1 ? '' : 's'} · Tap to preview'
                          : 'Tap to preview',
                      style: AppTextStyles.monoTiny
                          .copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.deepNavy.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.open_in_full_rounded,
                      size: 16, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Fullscreen Preview ───────────────────────────────────────────────────────

class _FullscreenPreview extends StatelessWidget {
  const _FullscreenPreview({required this.document});

  final Document document;

  bool get _isPdf => (document.mimeType ?? '').contains('pdf');
  bool get _isImage => (document.mimeType ?? '').startsWith('image/');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          document.name,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: _isPdf
          ? _PdfPreview(filePath: document.filePath)
          : _isImage
              ? _ImagePreview(filePath: document.filePath)
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.insert_drive_file_outlined,
                          size: 64, color: Colors.white54),
                      const SizedBox(height: 16),
                      Text(
                        'Preview not available',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ─── Title Area ───────────────────────────────────────────────────────────────

class _TitleArea extends StatelessWidget {
  const _TitleArea({
    required this.document,
    required this.catColor,
    required this.daysLeft,
  });

  final Document document;
  final Color catColor;
  final int? daysLeft;

  @override
  Widget build(BuildContext context) {
    final dimColor = catColor.withValues(alpha: 0.07);
    final showExpiryBadge = daysLeft != null && daysLeft! < 90;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          document.name,
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (document.category != null)
              _TitleBadge(
                backgroundColor: dimColor,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: catColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      document.category!.name,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: catColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            if (document.type != null)
              _TitleBadge(
                backgroundColor: AppColors.warmFill,
                child: Text(
                  document.type!.name,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (showExpiryBadge)
              _TitleBadge(
                backgroundColor: AppColors.accentDim,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      daysLeft! < 0
                          ? 'Expired'
                          : daysLeft == 0
                              ? 'Expires today'
                              : 'Expires in ${daysLeft}d',
                      style: AppTextStyles.monoTiny.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TitleBadge extends StatelessWidget {
  const _TitleBadge({
    required this.child,
    required this.backgroundColor,
    this.border,
  });

  final Widget child;
  final Color backgroundColor;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusXs),
        border: border,
      ),
      child: child,
    );
  }
}

// ─── Expiry Countdown Card ────────────────────────────────────────────────────

class _ExpiryCountdownCard extends StatelessWidget {
  const _ExpiryCountdownCard({required this.daysLeft});

  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final passedSegments = daysLeft >= 60
        ? 1
        : daysLeft >= 30
            ? 2
            : daysLeft >= 0
                ? 3
                : 4;

    final displayDays = daysLeft < 0 ? 'Expired' : '${daysLeft}d';

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.accentDim,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.12),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Expiration Countdown',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                displayDays,
                style: AppTextStyles.monoDisplay.copyWith(
                  color: AppColors.accent,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(4, (i) {
              final isPassed = i < passedSegments;
              final isCurrent = i == passedSegments - 1 && daysLeft >= 0;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 3 ? 3 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: isCurrent
                        ? LinearGradient(colors: [
                            AppColors.accent,
                            AppColors.accent.withValues(alpha: 0.15),
                          ])
                        : null,
                    color: isCurrent
                        ? null
                        : isPassed
                            ? AppColors.accent
                            : AppColors.accent.withValues(alpha: 0.12),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _ExpiryLabel('90 days ✓', passed: passedSegments > 0,
                  align: TextAlign.left),
              _ExpiryLabel('60 days ✓', passed: passedSegments > 1),
              _ExpiryLabel('30 days ✓', passed: passedSegments > 2),
              _ExpiryLabel(
                daysLeft < 0 ? 'Expired' : '$daysLeft days left',
                passed: true,
                isCurrent: true,
                align: TextAlign.right,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ExpiryButton(
                  label: 'Upload Renewal',
                  primary: true,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ExpiryButton(
                  label: 'Snooze',
                  primary: false,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpiryLabel extends StatelessWidget {
  const _ExpiryLabel(
    this.text, {
    required this.passed,
    this.isCurrent = false,
    this.align = TextAlign.center,
  });

  final String text;
  final bool passed;
  final bool isCurrent;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        style: AppTextStyles.monoTiny.copyWith(
          color: isCurrent
              ? AppColors.accent
              : passed
                  ? AppColors.accent.withValues(alpha: 0.6)
                  : AppColors.gray500,
          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
        ),
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ExpiryButton extends StatelessWidget {
  const _ExpiryButton({
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: primary
              ? AppColors.accent
              : AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: primary
              ? null
              : Border.all(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  width: 1.5,
                ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelLarge.copyWith(
            color: primary ? Colors.white : AppColors.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Shared Card Shell ────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepNavy.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.warmFill),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: AppColors.gray500),
                const SizedBox(width: 8),
                Text(label, style: AppTextStyles.monoSection),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing!,
                ],
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ─── Details Card ─────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.info_outline_rounded,
      label: 'DETAILS',
      trailing: _CardEditButton(
        onTap: () => EditMetadataSheet.show(context, document),
      ),
      child: _DetailsGrid(document: document),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.document});

  final Document document;

  // snake_case → Title Case
  static String _formatKey(String key) => key
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  // Detect values that deserve mono font: codes, money, phone numbers, pure numbers.
  static bool _isMono(dynamic value) {
    final s = value.toString();
    if (s.startsWith(r'$')) return true;
    if (RegExp(r'^\(?\d{3}\)?[\s\-]\d{3}[\s\-]\d{4}$').hasMatch(s)) return true;
    if (RegExp(r'^[A-Z0-9][A-Z0-9\-]{2,}$').hasMatch(s)) return true;
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(s)) return true;
    return false;
  }

  // Phone numbers get slate color to match the design reference.
  static Color? _valueColor(String key, dynamic value) {
    final s = value?.toString() ?? '';
    if (RegExp(r'^\(?\d{3}\)?[\s\-]\d{3}[\s\-]\d{4}$').hasMatch(s)) {
      return AppColors.slate;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasMetadata = document.metadata.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 20) / 2;
          final items = <Widget>[];

          if (hasMetadata) {
            // Type-specific fields from the metadata JSONB column.
            for (final entry in document.metadata.entries) {
              final value = entry.value;
              if (value == null || value.toString().isEmpty) continue;
              items.add(SizedBox(
                width: itemWidth,
                child: _InfoItem(
                  label: _formatKey(entry.key),
                  value: value.toString(),
                  mono: _isMono(value),
                  valueColor: _valueColor(entry.key, value),
                ),
              ));
            }
            if (document.expirationDate != null) {
              items.add(SizedBox(
                width: itemWidth,
                child: _InfoItem(
                  label: 'Expiration',
                  value: DateFormat('MMM d, yyyy')
                      .format(document.expirationDate!),
                  valueColor: AppColors.accent,
                ),
              ));
            }
          } else {
            // Generic fallback when no type-specific metadata is set.
            final uploadedDate =
                DateFormat('MMM d, yyyy').format(document.createdAt);
            final updatedDate =
                DateFormat('MMM d, yyyy').format(document.updatedAt);
            items.addAll([
              SizedBox(
                width: itemWidth,
                child: _InfoItem(
                    label: 'Category',
                    value: document.category?.name ?? '—'),
              ),
              SizedBox(
                width: itemWidth,
                child: _InfoItem(
                    label: 'Type', value: document.type?.name ?? '—'),
              ),
              SizedBox(
                width: itemWidth,
                child: _InfoItem(label: 'Uploaded', value: uploadedDate),
              ),
              SizedBox(
                width: itemWidth,
                child: _InfoItem(label: 'Updated', value: updatedDate),
              ),
              if (document.fileSizeBytes != null)
                SizedBox(
                  width: itemWidth,
                  child: _InfoItem(
                    label: 'Size',
                    value: _formatFileSize(document.fileSizeBytes!),
                    mono: true,
                  ),
                ),
              if (document.pageCount != null)
                SizedBox(
                  width: itemWidth,
                  child: _InfoItem(
                    label: 'Pages',
                    value: '${document.pageCount}',
                    mono: true,
                  ),
                ),
              if (document.expirationDate != null)
                SizedBox(
                  width: itemWidth,
                  child: _InfoItem(
                    label: 'Expiration',
                    value: DateFormat('MMM d, yyyy')
                        .format(document.expirationDate!),
                    valueColor: AppColors.accent,
                  ),
                ),
            ]);
          }

          return Wrap(spacing: 20, runSpacing: 14, children: items);
        },
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    this.mono = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool mono;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.monoTiny.copyWith(
            color: AppColors.gray500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: (mono ? AppTextStyles.monoLabel : AppTextStyles.bodySmall)
              .copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CardEditButton extends StatelessWidget {
  const _CardEditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        'Edit',
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent),
      ),
    );
  }
}

// ─── Linked To Card ───────────────────────────────────────────────────────────

class _LinkedToCard extends StatelessWidget {
  const _LinkedToCard({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final hasLinkedItem = document.linkedSystemId != null ||
        document.linkedApplianceId != null;

    return _InfoCard(
      icon: Icons.link_rounded,
      label: 'LINKED TO',
      child: Column(
        children: [
          _LinkedItemRow(
            icon: Icons.home_outlined,
            iconColor: AppColors.olive,
            iconBg: AppColors.oliveDim,
            title: 'Your Property',
            subtitle: 'Primary property',
            onTap: null,
          ),
          if (hasLinkedItem) ...[
            const Divider(
              height: 1,
              color: AppColors.warmFill,
              indent: 16,
              endIndent: 16,
            ),
            _LinkedItemRow(
              icon: document.linkedSystemId != null
                  ? Icons.settings_outlined
                  : Icons.kitchen_outlined,
              iconColor: AppColors.slate,
              iconBg: AppColors.slateDim,
              title: document.linkedSystemId != null
                  ? 'Linked System'
                  : 'Linked Appliance',
              subtitle: document.linkedSystemId != null ? 'System' : 'Appliance',
              onTap: () {
                final id = document.linkedSystemId ??
                    document.linkedApplianceId ??
                    '';
                final path = document.linkedSystemId != null
                    ? AppRoutes.homeSystemDetail
                        .replaceFirst(':systemId', id)
                    : AppRoutes.homeApplianceDetail
                        .replaceFirst(':applianceId', id);
                context.push(path);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _LinkedItemRow extends StatelessWidget {
  const _LinkedItemRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard - 1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.gray500),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right,
                  size: 14, color: AppColors.borderStrong),
          ],
        ),
      ),
    );
  }
}

// ─── Used In Card (reverse links) ─────────────────────────────────────────────

class _UsedInCard extends ConsumerWidget {
  const _UsedInCard({required this.documentId});

  final String documentId;

  static IconData _iconFor(String type) => switch (type) {
        'project' => Icons.folder_outlined,
        'appliance' => Icons.kitchen_outlined,
        _ => Icons.settings_outlined,
      };

  static String _typeLabel(String type) => switch (type) {
        'project' => 'Project',
        'appliance' => 'Appliance',
        _ => 'System',
      };

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
    return linksState.maybeWhen(
      data: (links) {
        if (links.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            const SizedBox(height: AppSizes.md),
            _InfoCard(
              icon: Icons.folder_open_outlined,
              label: 'USED IN',
              child: Column(
                children: [
                  for (int i = 0; i < links.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 1,
                        color: AppColors.warmFill,
                        indent: 16,
                        endIndent: 16,
                      ),
                    _LinkedItemRow(
                      icon: _iconFor(links[i].type),
                      iconColor: AppColors.slate,
                      iconBg: AppColors.slateDim,
                      title: links[i].label,
                      subtitle:
                          links[i].subtitle ?? _typeLabel(links[i].type),
                      onTap: () => _navigate(context, links[i]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

// ─── Notes Card ───────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.notes_rounded,
      label: 'NOTES',
      trailing: _CardEditButton(
        onTap: () => EditMetadataSheet.show(context, document),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Text(
          document.notes!,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

// ─── File Info Card ───────────────────────────────────────────────────────────

class _FileInfoCard extends StatelessWidget {
  const _FileInfoCard({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final ext = _extFromMime(document.mimeType);
    final addedDate = DateFormat('MMM d, yyyy').format(document.createdAt);
    final ocrStatus = document.ocrStatus;
    final ocrLabel = switch (ocrStatus) {
      'complete' => 'Complete',
      'processing' => 'Processing',
      'pending' => 'Pending',
      'failed' => 'Failed',
      _ => 'Not run',
    };
    final ocrColor = switch (ocrStatus) {
      'complete' => AppColors.olive,
      'processing' => AppColors.sand,
      'failed' => AppColors.error,
      _ => AppColors.gray500,
    };

    return _InfoCard(
      icon: Icons.insert_drive_file_outlined,
      label: 'FILE INFO',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [
            _FileMeta(icon: Icons.insert_drive_file_outlined, value: ext),
            if (document.fileSizeBytes != null)
              _FileMeta(
                icon: Icons.download_outlined,
                value: _formatFileSize(document.fileSizeBytes!),
              ),
            _FileMeta(
              icon: Icons.calendar_today_outlined,
              prefix: 'Added ',
              value: addedDate,
            ),
            _FileMeta(
              icon: Icons.access_time_rounded,
              prefix: 'OCR ',
              value: ocrLabel,
              valueColor: ocrColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _FileMeta extends StatelessWidget {
  const _FileMeta({
    required this.icon,
    required this.value,
    this.prefix,
    this.valueColor,
  });

  final IconData icon;
  final String value;
  final String? prefix;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.gray500),
        const SizedBox(width: 6),
        RichText(
          text: TextSpan(
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
            children: [
              if (prefix != null) TextSpan(text: prefix),
              TextSpan(
                text: value,
                style: TextStyle(
                  color: valueColor ?? AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Bottom Action Bar ────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.onShare,
    required this.onDownload,
    required this.onDelete,
  });

  final VoidCallback onShare;
  final VoidCallback onDownload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.warmOffWhite,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                _BarButton(
                  icon: Icons.ios_share_rounded,
                  style: _BarButtonStyle.secondary,
                  onTap: onShare,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BarButton(
                    icon: Icons.download_outlined,
                    label: 'Download',
                    style: _BarButtonStyle.primary,
                    onTap: onDownload,
                  ),
                ),
                const SizedBox(width: 10),
                _BarButton(
                  icon: Icons.delete_outline_rounded,
                  style: _BarButtonStyle.danger,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _BarButtonStyle { primary, secondary, danger }

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.style,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final _BarButtonStyle style;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final bg = isDisabled
        ? AppColors.warmFill
        : switch (style) {
            _BarButtonStyle.primary => AppColors.deepNavy,
            _BarButtonStyle.secondary => AppColors.surface,
            _BarButtonStyle.danger => AppColors.accentDim,
          };
    final fg = isDisabled
        ? AppColors.textDisabled
        : switch (style) {
            _BarButtonStyle.primary => AppColors.textInverse,
            _BarButtonStyle.secondary => AppColors.textSecondary,
            _BarButtonStyle.danger => AppColors.accent,
          };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: style == _BarButtonStyle.secondary
              ? Border.all(color: AppColors.border, width: 1.5)
              : null,
          boxShadow: style == _BarButtonStyle.secondary
              ? [
                  BoxShadow(
                    color: AppColors.deepNavy.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: AppTextStyles.labelLarge.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── PDF Preview (fullscreen) ─────────────────────────────────────────────────

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
    return PdfView(
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
                  size: AppSizes.iconLg, color: Colors.white54),
              const SizedBox(height: AppSizes.sm),
              Text(
                'PDF preview unavailable',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Image Preview (fullscreen) ───────────────────────────────────────────────

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
      if (mounted) {
        setState(() {
          _signedUrl = url;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }
    if (_signedUrl == null) {
      return Center(
        child: Text(
          'Preview unavailable',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white54),
        ),
      );
    }
    return PhotoView(
      imageProvider: NetworkImage(_signedUrl!),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 4,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      loadingBuilder: (_, event) => Center(
        child: CircularProgressIndicator(
          color: Colors.white70,
          value: event == null
              ? null
              : event.cumulativeBytesLoaded /
                  (event.expectedTotalBytes ?? 1),
        ),
      ),
    );
  }
}
