import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_docs_b.dart';
import '../../../../../core/theme/aurora_radius.dart';
import '../../../../../core/theme/aurora_scale.dart';
import '../../../../../core/theme/aurora_spacing.dart';
import '../../../../../core/theme/aurora_typography.dart';
import '../../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../../core/widgets/aurora/aurora_pressable.dart';

/// Thumbnail of the pages so far, the shutter, and Done.
class CameraControls extends StatelessWidget {
  const CameraControls({
    super.key,
    required this.pages,
    required this.busy,
    required this.onShoot,
    required this.onDone,
  });

  final List<File> pages;

  /// Capturing or combining pages: the shutter and Done wait.
  final bool busy;
  final VoidCallback onShoot;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final slot = a.of(AuroraCameraSizes.doneMinWidth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: slot),
          child: pages.isEmpty
              ? null
              : Align(
                  alignment: Alignment.centerLeft,
                  child: _PageStack(pages: pages),
                ),
        ),
        _Shutter(onTap: busy ? null : onShoot),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: slot),
          child: pages.isEmpty
              ? null
              : PrimaryButton(label: 'Done', onPressed: busy ? null : onDone),
        ),
      ],
    );
  }
}

class _Shutter extends StatelessWidget {
  const _Shutter({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final outer = a.of(AuroraCameraSizes.shutter);
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: 'Take picture',
      child: Container(
        width: outer,
        height: outer,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AuroraColors.paper,
            width: AuroraCameraSizes.shutterRing,
          ),
        ),
        child: Container(
          width: a.of(AuroraCameraSizes.shutterDisc),
          height: a.of(AuroraCameraSizes.shutterDisc),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AuroraColors.paper,
          ),
        ),
      ),
    );
  }
}

/// Last page on top of a tilted copy, with a lime count badge.
class _PageStack extends StatelessWidget {
  const _PageStack({required this.pages});

  final List<File> pages;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final side = a.of(AuroraCameraSizes.thumb);
    final offset = -a.of(AuroraCameraSizes.badgeOffset);
    return Semantics(
      label: '${pages.length} pages captured',
      child: SizedBox(
        width: side,
        height: side,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.rotate(
              angle: AuroraCameraSizes.thumbTilt,
              child: _Page(file: pages.first, side: side),
            ),
            _Page(file: pages.last, side: side),
            Positioned(
              right: offset,
              top: offset,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: a.of(AuroraCameraSizes.badge),
                  minHeight: a.of(AuroraCameraSizes.badge),
                ),
                padding: a.symmetric(horizontal: AuroraSpacing.space2),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AuroraColors.lime,
                  borderRadius: AuroraRadius.full,
                ),
                child: Text(
                  '${pages.length}',
                  style: AuroraType.number.copyWith(
                    color: AuroraColors.olive,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.file, required this.side});

  final File file;
  final double side;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(
      Radius.circular(AuroraCameraSizes.thumbRadius),
    );
    return Container(
      width: side,
      height: side,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AuroraCameraColors.pageThumb,
        borderRadius: radius,
        border: Border.all(
          color: AuroraColors.paper,
          width: AuroraCameraSizes.thumbBorder,
        ),
      ),
      child: Image.file(
        file,
        fit: BoxFit.cover,
        cacheWidth: (side * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
