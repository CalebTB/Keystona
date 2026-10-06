import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/providers/service_providers.dart';
import '../theme/aurora_colors.dart';
import '../theme/aurora_scale.dart';
import '../theme/aurora_sizes.dart';
import '../theme/aurora_spacing.dart';
import '../theme/aurora_typography.dart';

/// Full-width banner displayed when the device is offline (kit: HomeOffline).
///
/// Kit spec: white bar with an amber rule underneath and amber-deep text; no
/// tinted fill, no dismiss. Place inside a [Column] above main content so it
/// pushes content down without overlapping it.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, this.lastSynced});

  /// Optional time of the last sync, already formatted ("2:14 PM"). When set
  /// the second line ends with "LAST SYNCED <time>".
  final String? lastSynced;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);

    // While connectivity state is loading, assume online to avoid flicker.
    final isOnline = isOnlineAsync.value ?? true;

    if (isOnline) return const SizedBox.shrink();

    final a = context.aurora;
    final detail = lastSynced == null
        ? 'EMERGENCY STILL WORKS'
        : 'EMERGENCY STILL WORKS · LAST SYNCED ${lastSynced!.toUpperCase()}';

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: a.of(AuroraSpacing.screenPadH),
          vertical: a.of(AuroraSpacing.space4),
        ),
        decoration: const BoxDecoration(
          color: AuroraColors.paper,
          border: Border(
            bottom: BorderSide(
              color: AuroraColors.amber,
              width: AuroraSharedSizes.offlineRule,
            ),
          ),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.wifi_off_rounded,
                size: a.of(AuroraIconSizes.md),
                color: AuroraColors.amberDeep,
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space4)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('You’re offline', style: AuroraSharedType.offlineTitle),
                  Text(detail, style: AuroraSharedType.offlineSub),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
