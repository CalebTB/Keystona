import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/aurora_auth.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora_pressable.dart';
import '../auth_copy.dart';

/// Text-only action with a 44 pt tap target.
class AuthTextLink extends StatelessWidget {
  const AuthTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    required this.style,
    this.alignment = Alignment.center,
  });

  final String label;
  final VoidCallback onPressed;
  final TextStyle style;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      widthFactor: 1,
      child: AuroraPressable(
        onTap: onPressed,
        semanticLabel: label,
        enforceTouchTarget: true,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.aurora.of(AuroraSpacing.space1),
          ),
          child: Text(label, style: style, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

/// "Already have an account?  Log in" — prompt text and its link, wrapping
/// onto two lines when the screen is narrow or the text is large.
class AuthPromptRow extends StatelessWidget {
  const AuthPromptRow({
    super.key,
    required this.prompt,
    required this.linkLabel,
    required this.onPressed,
  });

  final String prompt;
  final String linkLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: context.aurora.of(AuroraSpacing.space1),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AuroraSizes.minTouch),
          child: Center(
            widthFactor: 1,
            child: Text(prompt, style: AuroraAuthType.prompt),
          ),
        ),
        AuthTextLink(
          label: linkLabel,
          onPressed: onPressed,
          style: AuroraAuthType.link,
        ),
      ],
    );
  }
}

/// "BY CONTINUING YOU AGREE TO THE TERMS AND PRIVACY POLICY".
///
/// [onTerms] and [onPrivacy] open the legal pages.
class AuthLegalLine extends StatefulWidget {
  const AuthLegalLine({
    super.key,
    required this.onTerms,
    required this.onPrivacy,
  });

  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  State<AuthLegalLine> createState() => _AuthLegalLineState();
}

class _AuthLegalLineState extends State<AuthLegalLine> {
  late final TapGestureRecognizer _terms;
  late final TapGestureRecognizer _privacy;

  @override
  void initState() {
    super.initState();
    _terms = TapGestureRecognizer()..onTap = () => widget.onTerms();
    _privacy = TapGestureRecognizer()..onTap = () => widget.onPrivacy();
  }

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final link = AuroraAuthType.legal.copyWith(
      color: AuroraColors.inkBody,
      decoration: TextDecoration.underline,
    );
    return Text.rich(
      TextSpan(
        style: AuroraAuthType.legal,
        children: [
          const TextSpan(text: AuthCopy.legalLead),
          TextSpan(text: AuthCopy.legalTerms, style: link, recognizer: _terms),
          const TextSpan(text: AuthCopy.legalAnd),
          TextSpan(
            text: AuthCopy.legalPrivacy,
            style: link,
            recognizer: _privacy,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Hairline rule with a centred caption ("OR WITH EMAIL").
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final rule = Expanded(
      child: Container(
        height: AuroraBorders.hairline,
        color: AuroraColors.inkBorder,
      ),
    );
    return Row(
      children: [
        rule,
        Flexible(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.aurora.of(AuroraSpacing.space5),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AuroraType.label,
            ),
          ),
        ),
        rule,
      ],
    );
  }
}
