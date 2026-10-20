import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../item_copy.dart';
import 'item_photo_image.dart';

/// One photo full screen on a dark ground, pinch to zoom, with a close
/// button. Open it with [show].
class ItemPhotoFullScreen extends StatelessWidget {
  const ItemPhotoFullScreen({super.key, required this.url});

  final String url;

  static Future<void> show(BuildContext context, String url) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ItemPhotoFullScreen(url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Scaffold(
      backgroundColor: AuroraColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(child: ItemPhotoImage(url: url, fit: BoxFit.contain)),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: AuroraPressable(
                onTap: () => Navigator.of(context).pop(),
                semanticLabel: ItemCopy.back,
                enforceTouchTarget: true,
                child: Icon(
                  Icons.close,
                  size: a.of(AuroraIconSizes.xl),
                  color: AuroraColors.paper,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
