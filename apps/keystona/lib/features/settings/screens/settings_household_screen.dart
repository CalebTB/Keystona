import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';

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
          padding: const EdgeInsets.all(AuroraSpacing.screenPadH)
              .copyWith(top: AuroraSpacing.space10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Household members',
                style: AuroraType.h1,
              ),
              const SizedBox(height: AuroraSpacing.space3),
              Text(
                'Invite people to access your home profile. Coming soon.',
                style: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
              ),
              const SizedBox(height: AuroraSpacing.space10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AuroraSpacing.space10),
                decoration: BoxDecoration(
                  color: AuroraColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AuroraColors.lime.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(CupertinoIcons.person_2,
                          size: 26, color: AuroraColors.lime),
                    ),
                    const SizedBox(height: AuroraSpacing.space7),
                    Text(
                      'No members yet',
                      style: AuroraType.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Household sharing will be available\nin a future update.',
                      style: AuroraType.bodySm.copyWith(
                        color: AuroraColors.inkSecondary,
                      ),
                      textAlign: TextAlign.center,
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
