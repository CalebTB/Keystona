import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_b.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../providers/document_upload_services_provider.dart';

/// "Or forward an email": the user's own address, with a Copy button.
///
/// Hidden until the address is known, and when it cannot be loaded.
class ForwardEmailCard extends ConsumerWidget {
  const ForwardEmailCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(documentForwardingAddressProvider).value;
    if (address == null) return const SizedBox.shrink();
    final a = context.aurora;
    return Padding(
      padding: EdgeInsets.only(top: a.of(AuroraSpacing.space4)),
      child: CustomPaint(
        foregroundPainter: const _DashedBorderPainter(),
        child: Padding(
          padding: a.symmetric(
            horizontal: AuroraSpacing.space6,
            vertical: AuroraSpacing.space5,
          ),
          child: Row(
            children: [
              Icon(
                Icons.mail_outline,
                size: a.of(AuroraIconSizes.md),
                color: AuroraColors.inkSubtle,
              ),
              SizedBox(width: a.of(AuroraSpacing.space5)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Or forward an email', style: AuroraType.rowTitle),
                    SizedBox(height: a.of(AuroraSpacing.space1)),
                    Text(
                      address,
                      style: AuroraType.meta.copyWith(
                        color: AuroraColors.cobalt,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: a.of(AuroraSpacing.space5)),
              _CopyPill(address: address),
            ],
          ),
        ),
      ),
    );
  }
}

class _CopyPill extends StatelessWidget {
  const _CopyPill({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      semanticLabel: 'Copy forwarding address',
      enforceTouchTarget: true,
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: address));
        if (!context.mounted) return;
        SnackbarService.showInfo(context, 'Address copied');
      },
      child: Container(
        padding: a.symmetric(
          horizontal: AuroraSpacing.space5,
          vertical: AuroraSpacing.space2,
        ),
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.full,
          border: Border.all(
            color: AuroraColors.inkBorderStrong,
            width: AuroraBorders.regular,
          ),
        ),
        child: Text('Copy', style: AuroraType.buttonSm),
      ),
    );
  }
}

/// Dashed rounded outline (ink 22%), drawn over the card.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AuroraColors.inkBorderStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = AuroraBorders.regular;
    final outline = Path()
      ..addRRect(AuroraRadius.lg.toRRect(Offset.zero & size));
    for (final metric in outline.computeMetrics()) {
      var at = 0.0;
      while (at < metric.length) {
        canvas.drawPath(
          metric.extractPath(at, at + AuroraUploadSizes.dashLength),
          paint,
        );
        at += AuroraUploadSizes.dashLength + AuroraUploadSizes.dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}
