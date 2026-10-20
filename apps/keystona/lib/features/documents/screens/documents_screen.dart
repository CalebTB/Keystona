import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../core/widgets/upgrade_sheet.dart';
import '../../../services/providers/service_providers.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../docs_copy.dart';
import '../models/docs_tab_data.dart';
import '../models/document_renewal.dart';
import '../providers/docs_tab_provider.dart';
import '../widgets/docs_scroll_page.dart';
import '../widgets/docs_tab/docs_empty_category_hint.dart';
import '../widgets/docs_tab/docs_empty_view.dart';
import '../widgets/docs_tab/docs_expiring_section.dart';
import '../widgets/docs_tab/docs_header.dart';
import '../widgets/docs_tab/docs_recent_section.dart';
import '../widgets/docs_tab/docs_search_field.dart';
import '../widgets/docs_tab/docs_tab_skeleton.dart';

/// The Docs tab (kit: DocsSearchLed, DocsEmpty).
///
/// Search-led: the search field opens the search screen, the one document that
/// needs action sits first, and the newest documents follow. An empty vault
/// shows one clear action instead.
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  /// Pushes [location] and refreshes the tab when the user comes back, since
  /// the pushed screen may have added, edited or deleted documents.
  Future<void> _push(String location) async {
    await context.push<void>(location);
    if (mounted) ref.invalidate(docsTabProvider);
  }

  Future<void> _refresh() async {
    ref.invalidate(docsTabProvider);
    try {
      await ref.read(docsTabProvider.future);
    } catch (_) {
      // The error state is shown by build().
    }
  }

  Future<void> _add(int count) async {
    if (!ref.read(isPremiumProvider) && count >= kFreeDocumentLimit) {
      await UpgradeSheet.show(context, config: DocsCopy.limitSheet);
      return;
    }
    await _push(AppRoutes.documentsUpload);
  }

  Future<void> _remind(DocsTabItem item) async {
    final repository = ref.read(docsTabRepositoryProvider);
    try {
      await repository.scheduleRenewalReminder(item.id);
    } on UnimplementedError {
      if (!mounted) return;
      SnackbarService.showInfo(context, DocsCopy.remindUnavailable);
    }
  }

  void _openDocument(DocsTabItem item) =>
      _push(AppRoutes.documentDetail.replaceFirst(':documentId', item.id));

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(docsTabProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final data = tab.value;

    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: DocsScrollPage(
        onRefresh: _refresh,
        fillRemaining: data == null,
        child: data != null
            ? _Content(
                data: data,
                isPremium: isPremium,
                onAdd: () => _add(data.totalCount),
                onSearch: () => _push(AppRoutes.documentsSearch),
                onExpiring: () => _push(AppRoutes.documentsExpiring),
                onUploadRenewal: (item) => _push(
                  DocumentRenewal.location(AppRoutes.documentsUpload, item.id),
                ),
                onRemind: _remind,
                onOpen: _openDocument,
              )
            : tab.hasError
            ? ErrorView(
                message: DocsCopy.loadError,
                onRetry: () => ref.invalidate(docsTabProvider),
              )
            : const DocsTabSkeleton(),
      ),
    );
  }
}

/// The loaded tab: the empty vault or the search-led list.
class _Content extends StatelessWidget {
  const _Content({
    required this.data,
    required this.isPremium,
    required this.onAdd,
    required this.onSearch,
    required this.onExpiring,
    required this.onUploadRenewal,
    required this.onRemind,
    required this.onOpen,
  });

  final DocsTabData data;
  final bool isPremium;
  final VoidCallback onAdd;
  final VoidCallback onSearch;
  final VoidCallback onExpiring;
  final ValueChanged<DocsTabItem> onUploadRenewal;
  final ValueChanged<DocsTabItem> onRemind;
  final ValueChanged<DocsTabItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final eyebrow = DocsCopy.eyebrow(data.totalCount, isPremium: isPremium);

    if (data.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DocsHeader(eyebrow: eyebrow),
          SizedBox(height: a.of(AuroraSpacing.space9)),
          DocsEmptyView(onAdd: onAdd, onScan: onAdd, onSuggestion: onAdd),
        ],
      );
    }

    final soon = data.soon();
    final urgent = data.urgent();
    final active = data.active;
    final hintName = data.emptyCategoryNames
        .where((name) => DocsCopy.hintFor(name) != null)
        .firstOrNull;
    final gap = SizedBox(height: a.of(AuroraSpacing.space8));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocsHeader(
          eyebrow: eyebrow,
          subtitle: urgent.isEmpty
              ? null
              : DocsCopy.expiringSubtitle(urgent.length),
          onAdd: onAdd,
        ),
        gap,
        DocsSearchField(onTap: onSearch),
        if (active.isNotEmpty) ...[
          gap,
          DocsExpiringSection(
            soon: soon,
            expiryCount: active.length,
            showCard: urgent.isNotEmpty,
            onUploadRenewal: onUploadRenewal,
            onRemind: onRemind,
            onOpen: onOpen,
            onSeeAllExpiring: onExpiring,
          ),
        ],
        gap,
        DocsRecentSection(
          items: data.recent,
          totalCount: data.totalCount,
          onOpen: onOpen,
          onSeeAll: () => onSearch(),
        ),
        if (hintName != null) ...[
          SizedBox(height: a.of(AuroraSpacing.space3)),
          DocsEmptyCategoryHint(
            title: DocsCopy.nothingIn(hintName),
            hint: DocsCopy.hintFor(hintName)!,
            onTap: onAdd,
          ),
        ],
      ],
    );
  }
}
