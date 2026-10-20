import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_docs_b.dart';
import '../../../../../core/theme/aurora_radius.dart';
import '../../../../../core/theme/aurora_scale.dart';
import '../../../../../core/theme/aurora_spacing.dart';
import '../../../../../core/theme/aurora_typography.dart';
import '../../../../../core/widgets/aurora/aurora_pressable.dart';

/// Close, the "SMART SCAN · PAGE 3" pill, and the flash toggle.
class CameraTopBar extends StatelessWidget {
  const CameraTopBar({
    super.key,
    required this.smart,
    required this.pageNumber,
    required this.flash,
    required this.onClose,
    required this.onFlash,
  });

  final bool smart;

  /// The page about to be shot, 1-based.
  final int pageNumber;
  final bool flash;
  final VoidCallback onClose;
  final VoidCallback onFlash;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundControl(icon: Icons.close, label: 'Close camera', onTap: onClose),
        Expanded(
          child: Center(
            child: _ModePill(smart: smart, pageNumber: pageNumber),
          ),
        ),
        _RoundControl(
          icon: Icons.bolt,
          label: 'Flash',
          selected: flash,
          onTap: onFlash,
        ),
      ],
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.smart, required this.pageNumber});

  final bool smart;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space5,
        vertical: AuroraSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: smart ? AuroraColors.coral : AuroraCameraColors.controlFill,
        borderRadius: AuroraRadius.full,
      ),
      child: Text(
        smart ? '★ SMART SCAN · PAGE $pageNumber' : 'PAGE $pageNumber',
        textAlign: TextAlign.center,
        style: AuroraType.label.copyWith(
          color: AuroraColors.paper,
          fontWeight: FontWeight.w700,
          letterSpacing: AuroraType.labelSm.letterSpacing,
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: label,
      selected: selected,
      child: Container(
        width: a.minControl(AuroraCameraSizes.control),
        height: a.minControl(AuroraCameraSizes.control),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AuroraColors.lime : AuroraCameraColors.controlFill,
        ),
        child: Icon(
          icon,
          size: a.of(AuroraCameraSizes.controlGlyph),
          color: selected ? AuroraColors.oliveDeep : AuroraColors.paper,
        ),
      ),
    );
  }
}
