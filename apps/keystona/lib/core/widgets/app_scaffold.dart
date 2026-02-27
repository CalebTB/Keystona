import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Thin wrapper around [Scaffold] used by every screen in Keystona.
///
/// Provides a consistent [AppBar] with the Keystona design system defaults
/// so individual screens never need to configure these values directly.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.floatingActionButton,
    this.actions,
    this.showBackButton = true,
    this.bottom,
  });

  /// Screen title displayed in the app bar. Null hides the title widget.
  final String? title;

  /// Main content of the screen. Automatically wrapped in [SafeArea].
  final Widget body;

  /// Optional FAB forwarded directly to [Scaffold].
  final Widget? floatingActionButton;

  /// Optional action widgets in the app bar trailing area.
  final List<Widget>? actions;

  /// When true and the navigator can pop, a back button is shown.
  /// Defaults to true; the [AppBar] leading widget respects this.
  final bool showBackButton;

  /// Optional [PreferredSizeWidget] (e.g. [TabBar]) shown below the app bar title.
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmOffWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: showBackButton && canPop,
        title: title != null
            ? Text(
                title!,
                style: AppTextStyles.h3,
              )
            : null,
        actions: actions,
        bottom: bottom,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: body,
      ),
    );
  }
}
