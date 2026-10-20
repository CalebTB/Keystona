import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/widgets/aurora/aurora_chip.dart';
import '../../appliance_copy.dart';
import '../../lifespan/lifespan_reading.dart';
import '../../models/appliance.dart';

/// The chip by the eyebrow: "HEALTHY" while it has life left, otherwise the
/// word that says why not (aging, past its life, needs repair).
class ApplianceHealthChip extends StatelessWidget {
  const ApplianceHealthChip({
    super.key,
    required this.status,
    required this.reading,
  });

  final ItemStatus status;
  final LifespanReading reading;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ItemStatus.needsRepair:
        return const StatusChip.dueSoon(label: ApplianceCopy.needsRepair);
      case ItemStatus.replaced:
        return _quiet(ApplianceCopy.replaced);
      case ItemStatus.removed:
        return _quiet(ApplianceCopy.removed);
      case ItemStatus.active:
        return switch (reading.band) {
          LifespanBand.past => const StatusChip.overdue(
            label: ApplianceCopy.pastLife,
          ),
          LifespanBand.endOfLife => const StatusChip.dueSoon(
            label: ApplianceCopy.atEndOfLife,
          ),
          LifespanBand.aging => const StatusChip.dueSoon(
            label: ApplianceCopy.aging,
          ),
          _ => const StatusChip.done(label: ApplianceCopy.healthy),
        };
    }
  }

  Widget _quiet(String label) => StatusChip(
    label: label,
    background: AuroraColors.paper,
    foreground: AuroraColors.inkSubtle,
    borderColor: AuroraColors.inkInputBorder,
  );
}
