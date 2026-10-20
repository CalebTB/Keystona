import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import 'reminders_back_link.dart';

/// A reminder screen with nothing to list: the back link at the top and an
/// error or empty state filling the rest.
class RemindersCenteredPage extends StatelessWidget {
  const RemindersCenteredPage({
    super.key,
    required this.backLabel,
    required this.onBack,
    required this.child,
  });

  final String backLabel;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: a.symmetric(
                horizontal: AuroraSpacing.screenPadH,
                vertical: AuroraSpacing.screenPadTop,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: RemindersBackLink(label: backLabel, onTap: onBack),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
