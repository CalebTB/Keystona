import 'package:flutter/material.dart';
import '../../../../../core/theme/aurora_colors.dart';


/// Floating camera button — 56px circle, accent background.
///
/// Use inside a [Stack] + [Positioned] for iOS (no FAB slot on
/// [CupertinoPageScaffold]); pass directly to [Scaffold.floatingActionButton]
/// on Android.
class PhotoCameraFAB extends StatelessWidget {
  const PhotoCameraFAB({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onTap,
      backgroundColor: AuroraColors.coral,
      elevation: 0,
      shape: const CircleBorder(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AuroraColors.coral,
          boxShadow: [
            BoxShadow(
              color: AuroraColors.coral.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.camera_alt_outlined,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
