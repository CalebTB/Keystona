import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/widgets/snackbar_service.dart';
import '../../../models/project_contractor.dart';
import '../../../models/project.dart';
import '../../../providers/project_contractors_provider.dart';
import '../../../widgets/contractor_form_sheet.dart';
import 'contractor_ledger_card.dart';
import 'contractors_ledger_skeleton.dart';
import 'ledger_filter_chips.dart';
import 'ledger_summary_banner.dart';

/// Full ledger view for the contractors sub-page.
///
/// Renders: eyebrow + heading → summary banner → filter chips → cards →
/// dashed "Add a contractor" footer card.
///
/// Filter logic is client-side from [List<ProjectContractor>].
class ContractorsLedgerView extends ConsumerStatefulWidget {
  const ContractorsLedgerView({
    super.key,
    required this.projectId,
    required this.project,
  });

  final String projectId;
  final Project project;

  @override
  ConsumerState<ContractorsLedgerView> createState() =>
      _ContractorsLedgerViewState();
}

class _ContractorsLedgerViewState
    extends ConsumerState<ContractorsLedgerView> {
  String? _activeFilter;

  List<ProjectContractor> _applyFilter(List<ProjectContractor> all) {
    return switch (_activeFilter) {
      'outstanding' => all.where((c) {
          final contract = c.contractAmount ?? 0.0;
          final paid = c.amountPaid ?? 0.0;
          return contract > 0 && paid < contract;
        }).toList(),
      'paid' => all.where((c) {
          final contract = c.contractAmount ?? 0.0;
          final paid = c.amountPaid ?? 0.0;
          return contract > 0 && paid >= contract;
        }).toList(),
      'rated' => all.where((c) => c.rating != null).toList(),
      _ => all,
    };
  }

  Future<void> _callContractor(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _removeContractor(
    BuildContext context,
    ProjectContractor c,
  ) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    bool confirmed = false;

    if (isIOS) {
      await showCupertinoRemoveDialog(context, c.contactName, () {
        confirmed = true;
      });
    } else {
      confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Remove Contractor'),
              content:
                  Text('Remove ${c.contactName} from this project?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text('Remove',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (!confirmed || !context.mounted) return;

    final notifier =
        ref.read(projectContractorsProvider(widget.projectId).notifier);
    try {
      await notifier.removeContractor(c.id);
      if (!context.mounted) return;
      SnackbarService.showSuccess(context, 'Contractor removed.');
    } catch (_) {
      if (!context.mounted) return;
      SnackbarService.showError(context, 'Could not remove contractor.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncContractors =
        ref.watch(projectContractorsProvider(widget.projectId));
    final isOnHold = widget.project.status == 'on_hold';

    return asyncContractors.when(
      loading: () => const ContractorsLedgerSkeleton(),
      error: (_, _) => _ErrorState(
        onRetry: () =>
            ref.invalidate(projectContractorsProvider(widget.projectId)),
      ),
      data: (all) {
        final filtered = _applyFilter(all);

        return RefreshIndicator(
          onRefresh: () async => ref
              .read(projectContractorsProvider(widget.projectId).notifier)
              .refresh(),
          child: CustomScrollView(
            slivers: [
              // ── Eyebrow + heading ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.md, AppSizes.md, AppSizes.md, 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ACTIVE PROJECT · ${all.length} VENDOR${all.length == 1 ? '' : 'S'}',
                            style: const TextStyle(
                              fontFamily: 'IBMPlexMono',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Project team',
                        style: GoogleFonts.fraunces(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Summary banner ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: LedgerSummaryBanner(contractors: all),
              ),

              // ── Filter chips ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: LedgerFilterChips(
                  activeFilter: _activeFilter,
                  onChanged: (f) => setState(() => _activeFilter = f),
                ),
              ),

              // ── Contractor cards ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                ),
                sliver: filtered.isEmpty
                    ? SliverToBoxAdapter(
                        child: _NoResultsState(
                          filter: _activeFilter,
                          onClear: () =>
                              setState(() => _activeFilter = null),
                        ),
                      )
                    : SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final c = filtered[i];
                          return Dismissible(
                            key: ValueKey(c.id),
                            direction: DismissDirection.endToStart,
                            background: const _DeleteBackground(),
                            confirmDismiss: (_) async {
                              await _removeContractor(ctx, c);
                              return false;
                            },
                            child: ContractorLedgerCard(
                              contractor: c,
                              isProjectOnHold: isOnHold,
                              onEdit: () => showContractorFormSheet(
                                context: ctx,
                                projectId: widget.projectId,
                                ref: ref,
                                existingContractor: c,
                              ),
                              onCall: c.contactPhone != null
                                  ? () => _callContractor(
                                      c.contactPhone!)
                                  : null,
                            ),
                          );
                        },
                      ),
              ),

              // ── Add contractor dashed card ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.md, 6, AppSizes.md, 0,
                  ),
                  child: _AddContractorCard(
                    onTap: () => showContractorFormSheet(
                      context: context,
                      projectId: widget.projectId,
                      ref: ref,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSizes.xxl + AppSizes.xl),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── iOS remove dialog helper ──────────────────────────────────────────────────

Future<void> showCupertinoRemoveDialog(
  BuildContext context,
  String name,
  VoidCallback onConfirm,
) async {
  await showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: const Text('Remove Contractor'),
      content: Text(
          'Remove $name from this project? The contact will stay in your contacts list.'),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () {
            onConfirm();
            Navigator.of(ctx).pop();
          },
          child: const Text('Remove'),
        ),
      ],
    ),
  );
}

// ── Add contractor dashed card ────────────────────────────────────────────────

class _AddContractorCard extends StatelessWidget {
  const _AddContractorCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.gray400,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Add a contractor',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── No results (filtered) ─────────────────────────────────────────────────────

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.filter, required this.onClear});

  final String? filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_list_off,
            size: AppSizes.iconXl,
            color: AppColors.gray400,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'No ${filter ?? ''} contractors',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          TextButton(
            onPressed: onClear,
            child: Text(
              'Clear filter',
              style: TextStyle(color: AppColors.deepNavy),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: AppSizes.iconXl, color: AppColors.error),
            const SizedBox(height: AppSizes.md),
            Text(
              "Couldn't load contractors",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepNavy),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Delete swipe background ───────────────────────────────────────────────────

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.person_remove_outlined, color: Colors.white),
    );
  }
}
