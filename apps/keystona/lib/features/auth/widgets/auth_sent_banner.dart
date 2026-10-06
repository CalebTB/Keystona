import 'package:flutter/cupertino.dart';

import '../../../core/theme/aurora_auth.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';
import '../../../core/theme/aurora_spacing.dart';

/// Lime check bubble with an olive tick — the kit's "done" mark.
class AuthDoneBubble extends StatelessWidget {
  const AuthDoneBubble({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final edge = a.of(size);
    return Container(
      width: edge,
      height: edge,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AuroraColors.lime,
      ),
      child: Icon(
        CupertinoIcons.check_mark,
        size: a.of(AuroraAuthSizes.sentCheck),
        color: AuroraColors.olive,
      ),
    );
  }
}

/// Olive-outlined status strip with a done bubble and a single line of text
/// ("Sent again · you can resend in 60s").
class AuthSentStrip extends StatelessWidget {
  const AuthSentStrip({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraAuthSizes.buttonHeight),
        ),
        padding: a.symmetric(
          horizontal: AuroraSpacing.pillH,
          vertical: AuroraSpacing.space3,
        ),
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.lg,
          border: Border.all(
            color: AuroraColors.olive,
            width: AuroraBorders.emphasis,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AuthDoneBubble(size: AuroraAuthSizes.sentBubble),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AuroraAuthType.sentTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Olive-outlined card: done bubble, a title and an explanation.
class AuthSentCard extends StatelessWidget {
  const AuthSentCard({super.key, required this.title, required this.body});

  final String title;
  final InlineSpan body;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: a.symmetric(
          horizontal: AuroraSpacing.space7,
          vertical: AuroraSpacing.space6,
        ),
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.xl,
          border: Border.all(
            color: AuroraColors.olive,
            width: AuroraBorders.emphasis,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthDoneBubble(size: AuroraAuthSizes.sentBubbleLg),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AuroraAuthType.sentTitle),
                  SizedBox(height: a.of(AuroraSpacing.space1)),
                  Text.rich(body, style: AuroraAuthType.sentBody),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
