import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// 44×56 colored file-type block with folded corner effect.
///
/// Displays the file type abbreviation (PDF, JPG, PNG, etc.) centered in a
/// rounded container. A subtle triangle at the top-right corner simulates
/// the classic folded-corner document icon.
class FileTypeIconBlock extends StatelessWidget {
  const FileTypeIconBlock({super.key, required this.mimeType});

  final String mimeType;

  static ({Color bg, Color fg, String label}) _infoFor(String mime) {
    final lower = mime.toLowerCase();
    if (lower == 'application/pdf' || lower.endsWith('/pdf')) {
      return (
        bg: const Color(0xFFF0E0DC),
        fg: const Color(0xFFB85638),
        label: 'PDF',
      );
    }
    if (lower.contains('jpeg') || lower.contains('jpg')) {
      return (
        bg: const Color(0xFFE0E8D8),
        fg: const Color(0xFF5A7050),
        label: 'JPG',
      );
    }
    if (lower.contains('png')) {
      return (
        bg: const Color(0xFFE0E8D8),
        fg: const Color(0xFF5A7050),
        label: 'PNG',
      );
    }
    if (lower.contains('heic') || lower.contains('heif')) {
      return (
        bg: const Color(0xFFE8D8E0),
        fg: const Color(0xFF7B5E7B),
        label: 'HEIC',
      );
    }
    if (lower.contains('vnd') ||
        lower.contains('word') ||
        lower.contains('docx') ||
        lower.contains('officedocument')) {
      return (
        bg: const Color(0xFFD8E0E8),
        fg: const Color(0xFF506A80),
        label: 'DOCX',
      );
    }
    return (
      bg: AppColors.surfaceVariant,
      fg: AppColors.textSecondary,
      label: 'FILE',
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _infoFor(mimeType);
    return SizedBox(
      width: 44,
      height: 56,
      child: Stack(
        children: [
          // Main block
          Container(
            width: 44,
            height: 56,
            decoration: BoxDecoration(
              color: info.bg,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              info.label,
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: info.fg,
                letterSpacing: 0,
              ),
            ),
          ),
          // Folded corner triangle — top-right 12×12 area
          Positioned(
            top: 0,
            right: 0,
            child: _FoldedCorner(fgColor: info.bg),
          ),
        ],
      ),
    );
  }
}

/// A small folded-corner triangle painted at the top-right of the file block.
class _FoldedCorner extends StatelessWidget {
  const _FoldedCorner({required this.fgColor});

  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(12, 12),
      painter: _CornerPainter(),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
