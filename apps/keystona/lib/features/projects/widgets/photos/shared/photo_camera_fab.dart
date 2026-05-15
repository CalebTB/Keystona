import 'package:flutter/material.dart';

// accent: #B85638
const Color _kAccent = Color(0xFFB85638);

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
      backgroundColor: _kAccent,
      elevation: 0,
      shape: const CircleBorder(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _kAccent,
          boxShadow: [
            BoxShadow(
              color: _kAccent.withValues(alpha: 0.35),
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
