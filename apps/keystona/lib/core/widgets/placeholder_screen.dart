import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import 'app_scaffold.dart';

/// Temporary stand-in widget used for routes that have not been implemented.
///
/// Every unbuilt route renders this widget with its route name so the
/// navigation shell is fully testable before feature screens exist.
///
/// Replace each usage with the real screen widget when the feature is built.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.name});

  /// Human-readable name shown as the app-bar title and centred body text.
  final String name;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: name,
      body: Center(
        child: Text(name, style: AppTextStyles.h2),
      ),
    );
  }
}
