import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_chip.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../../core/widgets/aurora/aurora_text_field.dart';
import '../../../../core/widgets/aurora/aurora_toggle_row.dart';
import '../../appliance_copy.dart';
import '../../models/appliance_specs.dart';
import '../shared/scan_field_box.dart';

/// SPECIFICATIONS, collapsed until opened: capacity, the washer type and the
/// Energy Star switch. The header's right side says how many came from the
/// scan, or HIDE while open.
class ApplianceSpecsSection extends StatelessWidget {
  const ApplianceSpecsSection({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.scannedCount,
    required this.capacity,
    required this.capacityFromScan,
    required this.type,
    required this.typeFromScan,
    required this.showType,
    required this.onType,
    required this.energyStar,
    required this.energyFromScan,
    required this.onEnergyStar,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final int scannedCount;
  final TextEditingController capacity;
  final bool capacityFromScan;
  final String? type;
  final bool typeFromScan;

  /// Only washers and dryers offer the load type.
  final bool showType;
  final ValueChanged<String?> onType;
  final bool energyStar;
  final bool energyFromScan;
  final ValueChanged<bool> onEnergyStar;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space6));
    return Padding(
      padding: EdgeInsets.only(top: a.of(AuroraSpacing.formSection)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuroraPressable(
            onTap: onToggle,
            semanticLabel: ApplianceCopy.specifications,
            enforceTouchTarget: true,
            child: Row(
              children: [
                Container(
                  width: a.of(AuroraSizes.sectionDot),
                  height: a.of(AuroraSizes.sectionDot),
                  decoration: const BoxDecoration(
                    color: AuroraColors.cobalt,
                    borderRadius: AuroraRadius.full,
                  ),
                ),
                SizedBox(width: a.of(AuroraSpacing.space2)),
                Expanded(
                  child: Text(
                    ApplianceCopy.specifications.toUpperCase(),
                    style: AuroraType.sectionTitle,
                  ),
                ),
                Flexible(
                  child: Text(
                    expanded || scannedCount == 0
                        ? (expanded
                              ? ApplianceCopy.specsHide
                              : ApplianceCopy.specsShow)
                        : ApplianceCopy.specsScanned(scannedCount),
                    textAlign: TextAlign.end,
                    style: AuroraType.label,
                  ),
                ),
                SizedBox(width: a.of(AuroraSpacing.space2)),
                Icon(
                  expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: a.of(AuroraIconSizes.sm),
                  color: AuroraColors.inkHelper,
                ),
              ],
            ),
          ),
          if (expanded) ...[
            gap,
            ScanFieldBox(
              fromScan: capacityFromScan,
              child: AuroraTextField(
                label: ApplianceCopy.capacity,
                controller: capacity,
                hintText: ApplianceCopy.capacityHint,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffix: Text(
                  ApplianceSpecs.capacityUnit,
                  style: AuroraType.body.copyWith(color: AuroraColors.inkHelper),
                ),
              ),
            ),
            if (showType) ...[
              gap,
              Text(ApplianceCopy.type.toUpperCase(), style: AuroraType.label),
              SizedBox(height: a.of(AuroraSpacing.space3)),
              ScanFieldBox(
                fromScan: typeFromScan,
                borderRadius: AuroraRadius.full,
                child: Wrap(
                  spacing: a.of(AuroraSpacing.space2),
                  runSpacing: a.of(AuroraSpacing.space2),
                  children: [
                    for (final t in ApplianceSpecs.washerTypes)
                      FilterPill(
                        label: t,
                        selected: type == t,
                        onTap: () => onType(type == t ? null : t),
                      ),
                  ],
                ),
              ),
            ],
            gap,
            ScanFieldBox(
              fromScan: energyFromScan,
              borderRadius: AuroraRadius.xl,
              child: AuroraToggleRow(
                label: ApplianceCopy.energyStar,
                helperText: ApplianceCopy.energyStarHelper,
                value: energyStar,
                onChanged: onEnergyStar,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
