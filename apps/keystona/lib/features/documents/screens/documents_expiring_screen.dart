import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_docs_c.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../models/document_renewal.dart';
import '../models/expiring_document.dart';
import '../models/expiring_groups.dart';
import '../providers/expiring_documents_provider.dart';
import '../widgets/expiring/expiring_ended_section.dart';
import '../widgets/expiring/expiring_group_section.dart';
import '../widgets/expiring/expiring_range_tabs.dart';
import '../widgets/expiring/expiring_skeleton.dart';
import '../widgets/shared/docs_back_link.dart';
import '../widgets/docs_scroll_page.dart';

/// Everything with an end date, by urgency: next 30 days, next 90, later,
/// then what already ended. Route: `/documents/expiring`.
class DocumentsExpiringScreen extends ConsumerStatefulWidget {
  const DocumentsExpiringScreen({super.key});

  @override
  ConsumerState<DocumentsExpiringScreen> createState() =>
      _DocumentsExpiringScreenState();
}

class _DocumentsExpiringScreenState
    extends ConsumerState<DocumentsExpiringScreen> {
  ExpiringRange _range = ExpiringRange.days90;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.documents);
    }
  }

  void _open(ExpiringDocument document) => context.push(
        AppRoutes.documentDetail.replaceFirst(':documentId', document.id),
      );

  Future<void> _refresh() async {
    ref.invalidate(expiringDocumentsProvider);
    await ref.read(expiringDocumentsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(expiringDocumentsProvider);
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: SafeArea(
        bottom: false,
        child: documents.when(
          loading: () => _page(
            count: null,
            body: const ExpiringSkeleton(),
          ),
          error: (_, _) => Column(
            children: [
              Padding(
                padding: context.aurora.symmetric(
                  horizontal: AuroraSpacing.screenPadH,
                  vertical: AuroraSpacing.screenPadTop,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DocsBackLink(label: 'Documents', onTap: _back),
                ),
              ),
              Expanded(
                child: ErrorView(
                  message: "Couldn't load your documents.",
                  onRetry: () => ref.invalidate(expiringDocumentsProvider),
                ),
              ),
            ],
          ),
          data: (list) => list.isEmpty
              ? Column(
                  children: [
                    Padding(
                      padding: context.aurora.symmetric(
                        horizontal: AuroraSpacing.screenPadH,
                        vertical: AuroraSpacing.screenPadTop,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DocsBackLink(label: 'Documents', onTap: _back),
                      ),
                    ),
                    Expanded(
                      child: EmptyState(
                        icon: CupertinoIcons.calendar,
                        title: 'Nothing has an end date',
                        subtitle:
                            'Add an end date to a warranty, policy or permit and it shows up here.',
                      ),
                    ),
                  ],
                )
              : _page(count: list.length, body: _content(list)),
        ),
      ),
    );
  }

  Widget _content(List<ExpiringDocument> list) {
    final a = context.aurora;
    final groups = ExpiringGroups.of(list, _range);
    final gap = SizedBox(height: a.of(AuroraSpacing.space9));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExpiringRangeTabs(
          selected: _range,
          onSelect: (r) => setState(() => _range = r),
        ),
        gap,
        if (!groups.hasUpcoming)
          Text(
            _range == ExpiringRange.days30
                ? 'Nothing ends in the next 30 days.'
                : 'Nothing ends in the next 90 days.',
            textAlign: TextAlign.center,
            style: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
          ),
        for (final group in groups.upcoming) ...[
          ExpiringGroupSection(
            group: group,
            onOpen: _open,
            onRenew: (document) => context.push(
              DocumentRenewal.location(AppRoutes.documentsUpload, document.id),
            ),
          ),
          gap,
        ],
        if (groups.ended.isNotEmpty) ...[
          ExpiringEndedSection(documents: groups.ended, onOpen: _open),
          gap,
        ],
        Text(
          'WE REMIND YOU 30 DAYS BEFORE EACH ONE · CHANGE IT IN SETTINGS',
          textAlign: TextAlign.center,
          style: AuroraType.helper,
        ),
      ],
    );
  }

  Widget _page({required int? count, required Widget body}) {
    final a = context.aurora;
    return DocsScrollPage(
      onRefresh: _refresh,
      topPadding: AuroraSpacing.screenPadTop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: DocsBackLink(label: 'Documents', onTap: _back),
          ),
          SizedBox(height: a.of(AuroraSpacing.space3)),
          Text(
            count == null
                ? 'EVERYTHING WITH AN END DATE'
                : 'EVERYTHING WITH AN END DATE · $count',
            style: AuroraType.label,
          ),
          SizedBox(height: a.of(AuroraSpacing.space2)),
          Semantics(
            header: true,
            child: Text('Expiring', style: AuroraDocsCType.screenTitle),
          ),
          SizedBox(height: a.of(AuroraSpacing.space7)),
          body,
        ],
      ),
    );
  }
}
