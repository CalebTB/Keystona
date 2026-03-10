import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/project_photo.dart';

/// Before/after comparison screen with a draggable divider.
///
/// The divider reveals the "before" photo on the left and "after" on the right.
class PhotoComparisonScreen extends StatefulWidget {
  const PhotoComparisonScreen({
    super.key,
    required this.beforePhoto,
    required this.afterPhoto,
  });

  final ProjectPhoto beforePhoto;
  final ProjectPhoto afterPhoto;

  @override
  State<PhotoComparisonScreen> createState() =>
      _PhotoComparisonScreenState();
}

class _PhotoComparisonScreenState extends State<PhotoComparisonScreen> {
  double _divider = 0.5;

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    Widget content = LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;

        return Stack(
          children: [
            // After photo — base layer.
            widget.afterPhoto.signedUrl != null
                ? PhotoView(
                    imageProvider:
                        NetworkImage(widget.afterPhoto.signedUrl!),
                    backgroundDecoration:
                        const BoxDecoration(color: Colors.black),
                  )
                : const ColoredBox(color: Colors.black),

            // Before photo — clipped to the left of the divider.
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: _divider,
                child: SizedBox(
                  width: w,
                  child: widget.beforePhoto.signedUrl != null
                      ? PhotoView(
                          imageProvider: NetworkImage(
                              widget.beforePhoto.signedUrl!),
                          backgroundDecoration:
                              const BoxDecoration(color: Colors.black),
                        )
                      : const ColoredBox(color: Colors.black),
                ),
              ),
            ),

            // Divider line.
            Positioned(
              left: _divider * w - 1.5,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: Colors.white),
            ),

            // Drag hit area around the divider.
            Positioned(
              left: _divider * w - 20,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _divider = ((_divider * w + details.delta.dx) / w)
                        .clamp(0.02, 0.98);
                  });
                },
                child: SizedBox(
                  width: 40,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.compare_arrows,
                          color: AppColors.deepNavy, size: 18),
                    ),
                  ),
                ),
              ),
            ),

            // Labels.
            const Positioned(top: 60, left: 12, child: _Label('BEFORE')),
            const Positioned(top: 60, right: 12, child: _Label('AFTER')),
          ],
        );
      },
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: Colors.black,
        navigationBar: const CupertinoNavigationBar(
          backgroundColor: Colors.black,
          middle: Text('Compare', style: TextStyle(color: Colors.white)),
        ),
        child: SafeArea(bottom: false, child: content),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Compare'),
      ),
      body: content,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall
            .copyWith(color: Colors.white, fontSize: 10),
      ),
    );
  }
}
