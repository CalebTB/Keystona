import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_docs_c.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/document.dart';
import '../providers/document_detail_provider.dart';
import '../providers/document_links_provider.dart';
import '../providers/document_removal.dart';
import '../providers/document_repositories_provider.dart';
import '../widgets/detail/document_delete_flow.dart';
import '../widgets/detail/document_detail_body.dart';
import '../widgets/detail/document_detail_top_bar.dart';
import '../widgets/detail/document_file_viewer.dart';
import '../widgets/docs_scroll_page.dart';
import '../widgets/document_detail_skeleton.dart';
import '../widgets/edit_metadata_sheet.dart';

/// Document detail: preview, coverage, what the document says, links, notes,
/// file facts, and the edit / share / delete actions.
///
/// Route: `/documents/:documentId`
class DocumentDetailScreen extends ConsumerStatefulWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  bool _deleting = false;

  DocumentDetailNotifier get _notifier =>
      ref.read(documentDetailProvider(widget.documentId).notifier);

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.documents);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(documentLinksProvider(widget.documentId));
    ref.invalidate(documentDetailProvider(widget.documentId));
    await ref.read(documentDetailProvider(widget.documentId).future);
  }

  Future<void> _share(Document document) async {
    final actions = ref.read(documentFileActionsProvider);
    try {
      final url = await _notifier.signedUrl();
      if (url == null) throw StateError('no url');
      await actions.share(url: url, title: document.name);
    } catch (_) {
      if (mounted) SnackbarService.showError(context, "Couldn't share document.");
    }
  }

  Future<void> _download() async {
    final actions = ref.read(documentFileActionsProvider);
    try {
      final url = await _notifier.signedUrl();
      if (url == null || !await actions.open(Uri.parse(url))) {
        throw StateError('cannot open');
      }
    } catch (_) {
      if (mounted) SnackbarService.showError(context, "Couldn't open download.");
    }
  }

  Future<void> _call(String phone) async {
    final actions = ref.read(documentFileActionsProvider);
    final opened = await actions.open(Uri(scheme: 'tel', path: phone));
    if (!opened && mounted) {
      SnackbarService.showError(context, "Couldn't start the call.");
    }
  }

  Future<void> _replace() async {
    try {
      await _notifier.replaceFile();
    } catch (_) {
      if (mounted) {
        SnackbarService.showInfo(context, "Replacing a file isn't available yet.");
      }
    }
  }

  Future<void> _edit(Document document) {
    final notifier = _notifier;
    return EditMetadataSheet.show(
      context,
      document: document,
      onSave: notifier.saveEdits,
    );
  }

  Future<void> _delete() async {
    final container = ProviderScope.containerOf(context);
    final id = widget.documentId;
    setState(() => _deleting = true);
    await DocumentDeleteFlow.run(
      context,
      delete: () => deleteDocument(container, id),
      restore: () => restoreDocument(container, id),
    );
    if (mounted) setState(() => _deleting = false);
  }

  void _openLink(DocumentLinkEntry entry) {
    final path = switch (entry.type) {
      DocumentLinkType.project =>
        AppRoutes.projectDetail.replaceFirst(':projectId', entry.id),
      DocumentLinkType.appliance =>
        AppRoutes.homeApplianceDetail.replaceFirst(':applianceId', entry.id),
      DocumentLinkType.system =>
        AppRoutes.homeSystemDetail.replaceFirst(':systemId', entry.id),
    };
    context.push(path);
  }

  Widget _page({required Widget topBar, required Widget child}) {
    final a = context.aurora;
    return DocsScrollPage(
      onRefresh: _refresh,
      topPadding: AuroraSpacing.screenPadTop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          topBar,
          SizedBox(height: a.of(AuroraDocsCSizes.sectionGap)),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(documentDetailProvider(widget.documentId));
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: SafeArea(
        bottom: false,
        child: detail.when(
          loading: () => _page(
            topBar: DocumentDetailTopBar(onBack: _back),
            child: const DocumentDetailSkeleton(),
          ),
          error: (_, _) => Column(
            children: [
              Padding(
                padding: context.aurora.symmetric(
                  horizontal: AuroraSpacing.screenPadH,
                  vertical: AuroraSpacing.screenPadTop,
                ),
                child: DocumentDetailTopBar(onBack: _back),
              ),
              Expanded(
                child: ErrorView(
                  message: "Couldn't load this document.",
                  onRetry: () =>
                      ref.invalidate(documentDetailProvider(widget.documentId)),
                ),
              ),
            ],
          ),
          data: (document) => _page(
            topBar: DocumentDetailTopBar(
              onBack: _back,
              onShare: () => _share(document),
              onEdit: () => _edit(document),
            ),
            child: DocumentDetailBody(
              document: document,
              onOpenFile: () => DocumentFileViewer.open(context, document),
              onClaim: _call,
              onOpenLink: _openLink,
              onEdit: () => _edit(document),
              onDownload: _download,
              onReplace: _replace,
              onDelete: _deleting ? null : _delete,
            ),
          ),
        ),
      ),
    );
  }
}
