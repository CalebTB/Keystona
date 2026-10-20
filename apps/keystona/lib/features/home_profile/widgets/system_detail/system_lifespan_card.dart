import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_home_shared.dart';
import '../../lifespan/lifespan_reading.dart';
import '../../models/system.dart';
import '../../models/system_reading.dart';
import '../../systems_copy.dart';
import '../shared/item_lifespan_card.dart';

/// The LIFESPAN card for a system: age, bar, "INSTALLED MAR 2021" and the
/// closing sentence with the years left in bold.
class SystemLifespanCard extends StatelessWidget {
  const SystemLifespanCard({super.key, required this.system, this.now});

  final HomeSystem system;

  /// Injectable clock for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final today = now ?? DateTime.now();
    final LifespanReading reading = system.reading(now: today);
    final installed = system.installedOn;
    final parts = SystemsCopy.lifespanBody(
      reading: reading,
      cost: system.estimatedReplacementCost,
      now: today.year,
    );
    return ItemLifespanCard(
      reading: reading,
      startLabel: installed == null ? null : SystemsCopy.installedOn(installed),
      body: TextSpan(
        children: [
          TextSpan(text: parts.before),
          if (parts.bold.isNotEmpty)
            TextSpan(
              text: parts.bold,
              style: AuroraHomeType.lifespanBody.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          if (parts.after.isNotEmpty) TextSpan(text: parts.after),
        ],
      ),
    );
  }
}
