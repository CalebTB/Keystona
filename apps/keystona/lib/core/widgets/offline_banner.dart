import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/providers/service_providers.dart';
import '../theme/aurora_colors.dart';
import '../theme/aurora_spacing.dart';
import '../theme/aurora_typography.dart';

/// Full-width banner displayed when the device is offline.
///
/// Aurora spec: butter background, wifi-off icon in inkSecondary,
/// body text in ink, no dismiss. Place inside a [Column] above main content
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
      color: AuroraColors.butter,
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.screenPadH,
        vertical: AuroraSpacing.space3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 16,
            color: AuroraColors.inkSecondary,
          ),
          const SizedBox(width: AuroraSpacing.space1),
          Text(
            'No internet connection',
            style: AuroraType.body.copyWith(
              color: AuroraColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
