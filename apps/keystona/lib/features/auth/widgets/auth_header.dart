import 'package:flutter/material.dart';

import '../../../core/theme/aurora_auth.dart';
import '../../../core/theme/aurora_scale.dart';

/// Screen title with its sub copy underneath.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AuroraAuthType.title),
        ),
        SizedBox(height: context.aurora.of(AuroraAuthSizes.titleGap)),
        Text(body, style: AuroraAuthType.subtitle),
      ],
    );
  }
}
