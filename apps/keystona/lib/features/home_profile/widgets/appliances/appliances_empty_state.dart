import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../appliance_copy.dart';

/// Nothing tracked yet: invites the first appliance, by scan or by hand.
class AppliancesEmptyState extends StatelessWidget {
  const AppliancesEmptyState({
    super.key,
    required this.onAdd,
    required this.onScan,
  });

  final VoidCallback onAdd;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.kitchen_outlined,
      title: ApplianceCopy.emptyTitle,
      subtitle: ApplianceCopy.emptyBody,
      accent: true,
      actionLabel: ApplianceCopy.emptyAction,
      onAction: onAdd,
      secondaryLabel: ApplianceCopy.emptyScan,
      onSecondary: onScan,
    );
  }
}
