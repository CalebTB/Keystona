import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/providers/service_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text_styles.dart';

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
      color: AppColors.warningLight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off,
            size: AppSizes.iconSm,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSizes.xs),
          Text(
            'No internet connection',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
