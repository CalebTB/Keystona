import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/error_view.dart';
import '../providers/emergency_hub_provider.dart';
import '../widgets/contacts_section.dart';
import '../widgets/emergency_hub_skeleton.dart';
import '../widgets/insurance_section.dart';

/// Emergency Hub main screen — lives at [AppRoutes.emergency].
///
/// Accessed via a quick-action button on the Home tab (NOT a bottom nav tab).
class EmergencyHubScreen extends ConsumerWidget {
  const EmergencyHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS ? const _IOSLayout() : const _AndroidLayout();
  }
}

// ── iOS layout ────────────────────────────────────────────────────────────────

class _IOSLayout extends ConsumerWidget {
  const _IOSLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      backgroundColor: AuroraColors.paper,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Emergency Hub'),
            backgroundColor: AuroraColors.paper,
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () =>
                ref.read(emergencyHubProvider.notifier).refresh(),
          ),
          const _ContentSliver(),
          const SliverToBoxAdapter(
              child: SizedBox(height: AuroraSpacing.space10)),
        ],
      ),
    );
  }
}

// ── Android layout ────────────────────────────────────────────────────────────

class _AndroidLayout extends ConsumerWidget {
  const _AndroidLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: RefreshIndicator(
        color: AuroraColors.coral,
        onRefresh: () => ref.read(emergencyHubProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text('Emergency Hub', style: AuroraType.h3),
              floating: true,
              backgroundColor: AuroraColors.paper,
              scrolledUnderElevation: 0,
              elevation: 0,
            ),
            const _ContentSliver(),
            const SliverToBoxAdapter(
                child: SizedBox(height: AuroraSpacing.space10)),
          ],
        ),
      ),
    );
  }
}

// ── Content sliver ────────────────────────────────────────────────────────────

class _ContentSliver extends ConsumerWidget {
  const _ContentSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(emergencyHubProvider);

    return overviewAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: EmergencyHubSkeleton(),
      ),
      error: (error, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(
          message: "Couldn't load Emergency Hub.",
          onRetry: () => ref.read(emergencyHubProvider.notifier).refresh(),
        ),
      ),
      data: (overview) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AuroraSpacing.screenPadH,
          AuroraSpacing.screenPadTop,
          AuroraSpacing.screenPadH,
          0,
        ),
        sliver: SliverList.list(
          children: [
            // ── Call 911 hero card ───────────────────────────────────────────
            _Call911Card(),
            const SizedBox(height: AuroraSpacing.space9),

            // ── Utility Shutoffs section ─────────────────────────────────────
            _SectionHeader(label: 'UTILITY SHUTOFFS'),
            const SizedBox(height: AuroraSpacing.space3),
            _ShutoffGrid(
              shutoffs: {
                'water': overview.shutoffFor('water'),
                'gas': overview.shutoffFor('gas'),
                'electrical': overview.shutoffFor('electrical'),
              },
              onTap: (type) => context.push(
                AppRoutes.emergencyShutoffDetail.replaceFirst(':type', type),
              ),
            ),
            const SizedBox(height: AuroraSpacing.space9),

            // ── Emergency Contacts section ───────────────────────────────────
            ContactsSection(
              favorites: overview.favoriteContacts,
              totalCount: overview.totalContactCount,
              onSeeAll: () => context.push(AppRoutes.emergencyContacts),
              onAddContact: () =>
                  context.push(AppRoutes.emergencyContactsAdd),
            ),
            const SizedBox(height: AuroraSpacing.space9),

            // ── Insurance section ────────────────────────────────────────────
            InsuranceSection(
              policies: overview.policies,
              onSeeAll: () => context.push(AppRoutes.emergencyInsurance),
              onAddPolicy: () => context.push(AppRoutes.emergencyInsurance),
            ),
            const SizedBox(height: AuroraSpacing.space9),

            _LastSyncedRow(lastSyncedAt: overview.lastSyncedAt),
          ],
        ),
      ),
    );
  }
}

// ── Call 911 hero card ────────────────────────────────────────────────────────

class _Call911Card extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AuroraColors.coral,
        borderRadius: AuroraRadius.xxl,
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Decorative yellow blob — top right
          Positioned(
            top: -32,
            right: -32,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AuroraColors.yellow.withValues(alpha: 0.32),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AuroraSpacing.space7),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AuroraColors.paper.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emergency_outlined,
                    color: AuroraColors.paper,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AuroraSpacing.space5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EMERGENCY',
                        style: AuroraType.label.copyWith(
                          color: AuroraColors.paper.withValues(alpha: 0.78),
                        ),
                      ),
                      const SizedBox(height: AuroraSpacing.space1),
                      Text(
                        'Call 911',
                        style: AuroraType.h1.copyWith(color: AuroraColors.paper),
                      ),
                      const SizedBox(height: AuroraSpacing.space1),
                      Text(
                        'Tap to call emergency services',
                        style: AuroraType.bodySm.copyWith(
                          color: AuroraColors.paper.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.phone_in_talk_outlined,
                  color: AuroraColors.paper,
                  size: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header (dot + label) ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AuroraColors.inkSecondary,
            borderRadius: AuroraRadius.xs,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AuroraType.label.copyWith(color: AuroraColors.inkSecondary),
        ),
      ],
    );
  }
}

// ── Shutoff grid (3-up row) ───────────────────────────────────────────────────

class _ShutoffGrid extends StatelessWidget {
  const _ShutoffGrid({required this.shutoffs, required this.onTap});

  final Map<String, dynamic> shutoffs;
  final void Function(String type) onTap;

  @override
  Widget build(BuildContext context) {
    const types = ['water', 'gas', 'electrical'];
    return Row(
      children: [
        for (int i = 0; i < types.length; i++) ...[
          Expanded(
            child: _ShutoffTile(
              utilityType: types[i],
              shutoff: shutoffs[types[i]],
              onTap: () => onTap(types[i]),
            ),
          ),
          if (i < types.length - 1)
            const SizedBox(width: AuroraSpacing.space3),
        ],
      ],
    );
  }
}

class _ShutoffTile extends StatelessWidget {
  const _ShutoffTile({
    required this.utilityType,
    required this.shutoff,
    required this.onTap,
  });

  final String utilityType;
  final dynamic shutoff;
  final VoidCallback onTap;

  bool get _isComplete => shutoff?.isComplete == true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 80),
        decoration: BoxDecoration(
          color: _isComplete ? AuroraColors.limeDim : AuroraColors.paper,
          borderRadius: AuroraRadius.lg,
          border: Border.all(
            color: _isComplete
                ? AuroraColors.limeDeep.withValues(alpha: 0.35)
                : AuroraColors.inkBorder,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.space3,
          vertical: AuroraSpacing.space3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _icon,
              size: 20,
              color: _isComplete ? AuroraColors.limeDeep : AuroraColors.inkSecondary,
            ),
            const SizedBox(height: AuroraSpacing.space2),
            Text(
              _label,
              style: AuroraType.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: _isComplete ? AuroraColors.limeDeep : AuroraColors.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              _isComplete ? 'Set up' : 'Not set up',
              style: AuroraType.labelSm.copyWith(
                color: _isComplete
                    ? AuroraColors.limeDeep
                    : AuroraColors.inkTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (utilityType) {
        'water' => Icons.water_drop_outlined,
        'gas' => Icons.local_fire_department_outlined,
        'electrical' => Icons.electric_bolt_outlined,
        _ => Icons.settings_outlined,
      };

  String get _label => switch (utilityType) {
        'water' => 'Water',
        'gas' => 'Gas',
        'electrical' => 'Electric',
        _ => utilityType,
      };
}

// ── Last synced row ───────────────────────────────────────────────────────────

class _LastSyncedRow extends StatelessWidget {
  const _LastSyncedRow({required this.lastSyncedAt});
  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    final label = lastSyncedAt == null
        ? 'Not yet synced for offline'
        : 'Last synced ${_formatTime(lastSyncedAt!)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.sync_outlined,
          size: 13,
          color: AuroraColors.inkSecondary,
        ),
        const SizedBox(width: AuroraSpacing.space1),
        Text(
          label,
          style: AuroraType.label.copyWith(color: AuroraColors.inkSecondary),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
