import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_typography.dart';
import '../../reminders_copy.dart';

/// "MORE SHOW UP AS YOU ADD SYSTEMS AND APPLIANCES".
class ReviewFooterNote extends StatelessWidget {
  const ReviewFooterNote({super.key});

  @override
  Widget build(BuildContext context) => Text(
    RemindersCopy.reviewFooter.toUpperCase(),
    textAlign: TextAlign.center,
    style: AuroraType.helper,
  );
}
