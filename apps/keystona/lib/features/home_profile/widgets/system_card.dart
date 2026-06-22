import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';

import '../../../core/router/app_router.dart';



import '../models/system.dart';

/// A 72px card representing a single home system in the grouped list.
///
/// Shows:
///   - Category icon in a tinted square
///   - System name (primary) and system type (secondary)
///   - Status chip on the right
///
/// Taps navigate to [AppRoutes.homeSystemDetail].
class SystemCard extends StatelessWidget {
  const SystemCard({super.key, required this.system});

  final HomeSystem system;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final path = AppRoutes.homeSystemDetail.replaceFirst(
          ':systemId',
          system.id,
        );
        context.push(path);
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(AuroraSpacing.space6),
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AuroraColors.inkBorder),
        ),
        child: Row(
          children: [
            // Category icon.
            _CategoryIcon(category: system.category),
            const SizedBox(width: AuroraSpacing.space5),

            // Name + type.
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    system.name,
                    style: AuroraType.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    system.systemType,
                    style: AuroraType.bodySm.copyWith(
                      color: AuroraColors.inkSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AuroraSpacing.space3),

            // Status chip.
            _StatusChip(status: system.status),
            const SizedBox(width: AuroraSpacing.space1),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AuroraColors.inkSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});

  final SystemCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AuroraColors.ink.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _iconFor(category),
        size: 22,
        color: AuroraColors.ink,
      ),
    );
  }

  IconData _iconFor(SystemCategory cat) => switch (cat) {
        SystemCategory.hvac => Icons.thermostat_outlined,
        SystemCategory.plumbing => Icons.water_drop_outlined,
        SystemCategory.electrical => Icons.electrical_services_outlined,
        SystemCategory.roofing => Icons.roofing_outlined,
        SystemCategory.foundation => Icons.foundation_outlined,
        SystemCategory.siding => Icons.home_outlined,
        SystemCategory.windowsDoors => Icons.door_front_door_outlined,
        SystemCategory.insulation => Icons.waves_outlined,
        SystemCategory.garage => Icons.garage_outlined,
        SystemCategory.other => Icons.build_outlined,
      };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ItemStatus.active => ('Active', AuroraColors.lime),
      ItemStatus.needsRepair => ('Repair', AuroraColors.yellow),
      ItemStatus.replaced => ('Replaced', AuroraColors.inkSecondary),
      ItemStatus.removed => ('Removed', AuroraColors.inkTertiary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: AuroraType.labelSm.copyWith(color: color),
      ),
    );
  }
}
