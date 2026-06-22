import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/providers/service_providers.dart';
import '../theme/aurora_colors.dart';
import '../theme/aurora_typography.dart';

/// Amber banner displayed at the top of the screen when the device is offline.
///
/// Wrap with [Consumer] internally so it rebuilds automatically when
/// connectivity changes. Place this above the main content inside a [Column]
/// so it pushes content down without overlapping it.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);

    // While connectivity state is loading, assume online to avoid flicker.
    final isOnline = isOnlineAsync.value ?? true;

    if (isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AuroraColors.yellowDim,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off,
            size: 16,
            color: AuroraColors.yellowDeep,
          ),
          const SizedBox(width: 4),
          Text(
            'No internet connection',
            style: AuroraType.bodySm.copyWith(
              fontWeight: FontWeight.w600,
              color: AuroraColors.yellowDeep,
            ),
          ),
        ],
      ),
    );
  }
}
