import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/widgets/aurora/aurora_chip.dart';
import '../../presenters/system_detail_view.dart';

/// The outlined chip beside the eyebrow: words plus color, never color alone.
class SystemStatusChip extends StatelessWidget {
  const SystemStatusChip({super.key, required this.chip});

  final SystemChip chip;

  @override
  Widget build(BuildContext context) => switch (chip.tone) {
    SystemChipTone.healthy => StatusChip(
      label: chip.label,
      background: AuroraColors.paper,
      foreground: AuroraColors.oliveDeep,
      borderColor: AuroraColors.limeDeep,
    ),
    SystemChipTone.soon => StatusChip.dueSoon(label: chip.label),
    SystemChipTone.overdue => StatusChip.overdue(label: chip.label),
    SystemChipTone.muted => StatusChip(
      label: chip.label,
      background: AuroraColors.paper,
      foreground: AuroraColors.inkSecondary,
      borderColor: AuroraColors.inkBorderStrong,
    ),
  };
}
