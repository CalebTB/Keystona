import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';

/// The frame of a form screen: safe area, scrolls above the keyboard, content
/// centred and width-capped on wide screens.
class SystemFormPage extends StatelessWidget {
  const SystemFormPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: a.contentMaxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  a.of(AuroraSpacing.screenPadH),
                  a.of(AuroraSpacing.screenPadTop),
                  a.of(AuroraSpacing.screenPadH),
                  a.of(AuroraSpacing.screenPadBottom),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
