import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora.dart';

class SettingsHouseholdScreen extends StatelessWidget {
  const SettingsHouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AuroraColors.paper,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AuroraColors.paper,
        border: null,
        middle: const Text('Household'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Text('Back'),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSpacing.screenPadH,
          ).copyWith(top: AuroraSpacing.space7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section header ────────────────────────────────────────
              const _SectionHeader(
                dot: AuroraColors.cobalt,
                label: 'MEMBERS',
              ),
              const SizedBox(height: AuroraSpacing.space3),

              // ── Empty state card — paper bg, inkBorder ────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AuroraSpacing.space10),
                decoration: BoxDecoration(
                  color: AuroraColors.paper,
                  borderRadius: AuroraRadius.xl,
                  border: Border.all(color: AuroraColors.inkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar circle
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AuroraColors.cobaltDim,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.person_2,
                        size: 26,
                        color: AuroraColors.cobalt,
                      ),
                    ),
                    const SizedBox(height: AuroraSpacing.space7),
                    Text(
                      'No members yet',
                      style: AuroraType.h3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Household sharing will be available\nin a future update.',
                      style: AuroraType.bodySm.copyWith(
                        color: AuroraColors.inkSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AuroraSpacing.space8),
                    // Invite button — cobalt (SaveButton)
                    SaveButton(
                      label: 'Invite a member',
                      onPressed: null, // coming soon
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section header — dot + label ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.dot, required this.label});

  final Color dot;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: dot,
            borderRadius: const BorderRadius.all(Radius.circular(2)),
          ),
        ),
        const SizedBox(width: 6),
        Text(label.toUpperCase(), style: AuroraType.label),
      ],
    );
  }
}
