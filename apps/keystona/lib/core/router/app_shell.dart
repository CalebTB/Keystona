import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_radius.dart';
import '../theme/aurora_scale.dart';
import '../theme/aurora_sizes.dart';
import '../theme/aurora_spacing.dart';
import '../theme/aurora_tab_icons.dart';
import '../theme/aurora_typography.dart';

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
      backgroundColor: AuroraColors.paper,
      body: navigationShell,
      bottomNavigationBar: AppTabBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// Aurora tab bar (kit nav "Main tabs"): paper surface, hairline top border,
/// five equal columns. Inactive tabs are ink 35%; the active tab is coral with
/// a coral bar on top. Height is [AuroraSizes.tabBarHeight] at minimum and
/// grows with the text scale and the bottom safe-area inset.
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _tabs = [
    _TabItem(label: 'Home', icon: AuroraTabIcon.home),
    _TabItem(label: 'Docs', icon: AuroraTabIcon.docs),
    _TabItem(label: 'Tasks', icon: AuroraTabIcon.tasks),
    _TabItem(label: 'Projects', icon: AuroraTabIcon.projects),
    _TabItem(label: 'Settings', icon: AuroraTabIcon.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    final bottomPad = math.max(inset, a.of(AuroraSharedSizes.tabPadBottomMin));
    return Container(
      constraints: BoxConstraints(minHeight: a.of(AuroraSizes.tabBarHeight)),
      decoration: const BoxDecoration(
        color: AuroraColors.paper,
        border: Border(
          top: BorderSide(
            color: AuroraColors.inkBorder,
            width: AuroraBorders.hairline,
          ),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Semantics(
        container: true,
        label: 'Main tabs',
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _TabCell(
                    item: _tabs[i],
                    active: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabCell extends StatelessWidget {
  const _TabCell({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _TabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final color = active ? AuroraColors.coral : AuroraColors.inkPlaceholder;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AuroraSizes.minTouch),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              if (active)
                Container(
                  width: a.of(AuroraSharedSizes.tabIndicatorWidth),
                  height: a.of(AuroraSharedSizes.tabIndicatorHeight),
                  decoration: const BoxDecoration(
                    color: AuroraColors.coral,
                    borderRadius: AuroraSharedRadius.barBottom,
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(
                  top: a.of(AuroraSharedSizes.tabPadTop),
                  left: a.of(AuroraSpacing.space1),
                  right: a.of(AuroraSpacing.space1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: Size.square(a.of(AuroraIconSizes.lg)),
                      painter: AuroraTabIconPainter(
                        icon: item.icon,
                        color: color,
                      ),
                    ),
                    SizedBox(height: a.of(AuroraSharedSizes.tabIconLabelGap)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        softWrap: false,
                        style: AuroraType.tabLabel.copyWith(
                          color: color,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.label, required this.icon});
  final String label;
  final AuroraTabIcon icon;
}
