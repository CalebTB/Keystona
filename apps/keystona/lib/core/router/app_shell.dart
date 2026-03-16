import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Persistent bottom-navigation shell that wraps the five primary tabs.
///
/// Each tab maintains its own navigation stack via [StatefulShellRoute.indexedStack].
/// Tab state is preserved when switching — the user returns to where they left
/// off in each branch.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      body: navigationShell,
      bottomNavigationBar: _AppTabBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

// ── Custom frosted-glass tab bar ──────────────────────────────────────────────

class _AppTabBar extends StatelessWidget {
  const _AppTabBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _tabs = [
    _TabItem(label: 'Home',     icon: _TabIcon.home),
    _TabItem(label: 'Docs',     icon: _TabIcon.docs),
    _TabItem(label: 'Tasks',    icon: _TabIcon.tasks),
    _TabItem(label: 'Projects', icon: _TabIcon.projects),
    _TabItem(label: 'Settings', icon: _TabIcon.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 56 + bottomPad,
          decoration: const BoxDecoration(
            color: Color(0xEBF6F2ED), // rgba(246,242,237,0.92)
            border: Border(
              top: BorderSide(color: Color(0x0F000000), width: 0.5),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTap(i),
                        behavior: HitTestBehavior.opaque,
                        child: _TabCell(
                          item: _tabs[i],
                          active: i == currentIndex,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(height: bottomPad),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabCell extends StatelessWidget {
  const _TabCell({required this.item, required this.active});

  final _TabItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textTertiary;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Top indicator bar — only visible on active tab.
        if (active)
          Container(
            width: 20,
            height: 3,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
            ),
          ),

        // Icon + label column.
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TabSvgIcon(icon: item.icon, color: color),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── SVG icon painter ──────────────────────────────────────────────────────────

enum _TabIcon { home, docs, tasks, projects, settings }

class _TabSvgIcon extends StatelessWidget {
  const _TabSvgIcon({required this.icon, required this.color});

  final _TabIcon icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _TabIconPainter(icon: icon, color: color),
    );
  }
}

class _TabIconPainter extends CustomPainter {
  const _TabIconPainter({required this.icon, required this.color});

  final _TabIcon icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Scale from 24×24 viewBox to actual size.
    final sx = size.width / 24;
    final sy = size.height / 24;
    canvas.scale(sx, sy);

    switch (icon) {
      case _TabIcon.home:
        // M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z
        final path = Path()
          ..moveTo(3, 9)
          ..lineTo(12, 2)
          ..lineTo(21, 9)
          ..lineTo(21, 20)
          ..arcToPoint(const Offset(19, 22),
              radius: const Radius.circular(2))
          ..lineTo(5, 22)
          ..arcToPoint(const Offset(3, 20),
              radius: const Radius.circular(2))
          ..close();
        canvas.drawPath(path, paint);

      case _TabIcon.docs:
        // M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z  +  polyline 14 2 14 8 20 8
        final body = Path()
          ..moveTo(14, 2)
          ..lineTo(6, 2)
          ..arcToPoint(const Offset(4, 4),
              radius: const Radius.circular(2))
          ..lineTo(4, 20)
          ..arcToPoint(const Offset(6, 22),
              radius: const Radius.circular(2))
          ..lineTo(18, 22)
          ..arcToPoint(const Offset(20, 20),
              radius: const Radius.circular(2))
          ..lineTo(20, 8)
          ..close();
        canvas.drawPath(body, paint);
        final fold = Path()
          ..moveTo(14, 2)
          ..lineTo(14, 8)
          ..lineTo(20, 8);
        canvas.drawPath(fold, paint);

      case _TabIcon.tasks:
        // Checkmark-list: two horizontal lines + a check mark.
        // Line 1
        canvas.drawLine(const Offset(9, 8), const Offset(19, 8), paint);
        // Line 2
        canvas.drawLine(const Offset(9, 12), const Offset(19, 12), paint);
        // Line 3
        canvas.drawLine(const Offset(9, 16), const Offset(19, 16), paint);
        // Check circle on the left
        canvas.drawCircle(const Offset(5, 8), 2, paint);
        canvas.drawCircle(const Offset(5, 12), 2, paint);
        canvas.drawCircle(const Offset(5, 16), 2, paint);

      case _TabIcon.projects:
        // Four rounded squares in a 2×2 grid
        final rr = RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 3, 7, 7), const Radius.circular(1.5));
        final rr2 = RRect.fromRectAndRadius(
            const Rect.fromLTWH(14, 3, 7, 7), const Radius.circular(1.5));
        final rr3 = RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 14, 7, 7), const Radius.circular(1.5));
        final rr4 = RRect.fromRectAndRadius(
            const Rect.fromLTWH(14, 14, 7, 7), const Radius.circular(1.5));
        canvas
          ..drawRRect(rr, paint)
          ..drawRRect(rr2, paint)
          ..drawRRect(rr3, paint)
          ..drawRRect(rr4, paint);

      case _TabIcon.settings:
        // Gear: center circle + 8-tooth cog outline.
        canvas.drawCircle(const Offset(12, 12), 3, paint);
        final gear = Path();
        const double ro = 9.5; // outer radius
        const double ri = 7.8; // inner radius (between teeth)
        const int teeth = 8;
        for (int i = 0; i < teeth; i++) {
          final a0 = (i / teeth) * math.pi * 2 - math.pi / 2;
          final a1 = a0 + (0.35 / teeth) * math.pi * 2;
          final a2 = a0 + (0.65 / teeth) * math.pi * 2;
          final a3 = a0 + (1.0 / teeth) * math.pi * 2;
          if (i == 0) {
            gear.moveTo(12 + ri * math.cos(a0), 12 + ri * math.sin(a0));
          }
          gear
            ..lineTo(12 + ro * math.cos(a1), 12 + ro * math.sin(a1))
            ..lineTo(12 + ro * math.cos(a2), 12 + ro * math.sin(a2))
            ..lineTo(12 + ri * math.cos(a3), 12 + ri * math.sin(a3));
        }
        gear.close();
        canvas.drawPath(gear, paint);
    }
  }

  @override
  bool shouldRepaint(_TabIconPainter old) =>
      old.icon != icon || old.color != color;
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _TabItem {
  const _TabItem({required this.label, required this.icon});
  final String label;
  final _TabIcon icon;
}
