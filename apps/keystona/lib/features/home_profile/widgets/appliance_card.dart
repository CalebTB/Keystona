import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../models/appliance.dart';

abstract final class ApplianceCategoryIcons {
  static const Map<ApplianceCategory, IconData> _map = {
    ApplianceCategory.kitchen: Icons.kitchen,
    ApplianceCategory.laundry: Icons.local_laundry_service,
    ApplianceCategory.climate: Icons.ac_unit,
    ApplianceCategory.cleaning: Icons.cleaning_services,
    ApplianceCategory.outdoor: Icons.yard,
    ApplianceCategory.bathroom: Icons.bathtub,
    ApplianceCategory.other: Icons.devices_other,
  };

  static IconData forCategory(ApplianceCategory category) =>
      _map[category] ?? Icons.devices_other;
}

class ApplianceCard extends StatelessWidget {
  const ApplianceCard({super.key, required this.appliance});
  final Appliance appliance;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.push('${AppRoutes.homeAppliances}/${appliance.id}'),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.space5,
          vertical: AuroraSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.lg,
          border: Border.all(color: AuroraColors.inkBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AuroraColors.ink.withValues(alpha: 0.08),
                borderRadius: AuroraRadius.sm,
              ),
              child: Icon(
                ApplianceCategoryIcons.forCategory(appliance.category),
                size: 22,
                color: AuroraColors.ink,
              ),
            ),
            const SizedBox(width: AuroraSpacing.space5),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appliance.name,
                    style: AuroraType.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
                      style: AuroraType.bodySm.copyWith(color: AuroraColors.inkSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AuroraSpacing.space3),
            _StatusBadge(status: appliance.status),
            const SizedBox(width: AuroraSpacing.space1),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AuroraColors.inkSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String get _subtitle {
    final parts = <String>[
      if (appliance.brand != null) appliance.brand!,
      if (appliance.modelNumber != null) appliance.modelNumber!,
    ];
    return parts.join(' · ');
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space3,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: AuroraRadius.full,
      ),
      child: Text(
        status.label,
        style: AuroraType.labelSm.copyWith(color: _textColor),
      ),
    );
  }

  Color get _bgColor => switch (status) {
        ItemStatus.active => AuroraColors.limeDim,
        ItemStatus.needsRepair => AuroraColors.yellowDim,
        ItemStatus.replaced => AuroraColors.inkBorder,
        ItemStatus.removed => AuroraColors.butter,
      };

  Color get _textColor => switch (status) {
        ItemStatus.active => AuroraColors.limeDeep,
        ItemStatus.needsRepair => AuroraColors.yellowDeep,
        ItemStatus.replaced => AuroraColors.inkSecondary,
        ItemStatus.removed => AuroraColors.inkSecondary,
      };
}
