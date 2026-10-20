import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_b.dart';
import '../../../../core/theme/aurora_motion.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../models/scan_prefill.dart';
import '../../systems_copy.dart';
import 'scan_frame.dart';
import 'scan_hint_pill.dart';
import 'scan_kind_switch.dart';
import 'scan_shutter.dart';

/// Step two of ScanFlow: the framed label view, what it says, the kind switch
/// and the shutter (or "Review details" once a label was read).
class ScanCameraView extends StatelessWidget {
  const ScanCameraView({
    super.key,
    required this.kind,
    required this.hint,
    required this.found,
    required this.busy,
    required this.online,
    required this.onBack,
    required this.onKind,
    required this.onShutter,
    required this.onReview,
    required this.onTypeItIn,
  });

  final ScanKind kind;
  final String hint;

  /// A label was read: lime brackets, "Review details".
  final bool found;
  final bool busy;
  final bool online;
  final VoidCallback onBack;
  final ValueChanged<ScanKind> onKind;
  final VoidCallback onShutter;
  final VoidCallback onReview;
  final VoidCallback onTypeItIn;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final title = kind == ScanKind.system
        ? SystemsCopy.scanSystemCamera
        : SystemsCopy.scanApplianceCamera;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.1),
          radius: 1.1,
          colors: [AuroraHomeBColors.cameraCentre, AuroraHomeBColors.cameraEdge],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: a.symmetric(horizontal: AuroraSpacing.space5),
          child: Column(
            children: [
              Row(
                children: [
                  AuroraPressable(
                    onTap: onBack,
                    semanticLabel: SystemsCopy.scanBack,
                    enforceTouchTarget: true,
                    child: Container(
                      width: a.minControl(AuroraSizes.minTouch),
                      height: a.minControl(AuroraSizes.minTouch),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AuroraHomeBColors.cameraChip,
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        size: a.of(AuroraIconSizes.xl),
                        color: AuroraColors.paper,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AuroraType.h3.copyWith(color: AuroraColors.paper),
                    ),
                  ),
                  SizedBox.square(
                    dimension: a.minControl(AuroraSizes.minTouch),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: a.of(AuroraHomeBSizes.frameMinStage),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScanFrame(found: found),
                        SizedBox(height: a.of(AuroraSpacing.space8)),
                        ScanHintPill(text: hint, found: found, busy: busy),
                      ],
                    ),
                  ),
                ),
              ),
              ScanKindSwitch(kind: kind, onChanged: onKind),
              SizedBox(height: a.of(AuroraSpacing.space8)),
              if (found)
                _ReviewButton(onTap: onReview)
              else
                Opacity(
                  opacity: online ? 1 : AuroraOpacity.disabled,
                  child: ScanShutter(onTap: busy ? null : onShutter),
                ),
              AuroraPressable(
                onTap: onTypeItIn,
                semanticLabel: SystemsCopy.scanTypeItIn,
                enforceTouchTarget: true,
                child: Padding(
                  padding: a.symmetric(vertical: AuroraSpacing.space3),
                  child: Text(
                    SystemsCopy.scanTypeItIn,
                    style: AuroraType.button.copyWith(
                      color: AuroraHomeBColors.cameraTextSoft,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewButton extends StatelessWidget {
  const _ReviewButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      PrimaryButton(label: SystemsCopy.scanReview, onPressed: onTap);
}
