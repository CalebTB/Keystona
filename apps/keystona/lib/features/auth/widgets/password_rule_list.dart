import 'package:flutter/cupertino.dart';

import '../../../core/theme/aurora_auth.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../auth_copy.dart';
import '../models/password_rules.dart';

/// "Password needs" checklist: an empty circle per rule that fills olive with a
/// lime check once the password meets it. Words always say what is needed.
class PasswordRuleList extends StatelessWidget {
  const PasswordRuleList({super.key, required this.rules});

  final PasswordRules rules;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final items = <({String text, bool met})>[
      (text: AuthCopy.ruleLength, met: rules.length),
      (text: AuthCopy.ruleCase, met: rules.mixedCase),
      (text: AuthCopy.ruleNumber, met: rules.number),
    ];
    return Semantics(
      label: AuthCopy.passwordNeeds,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items) ...[
            _RuleRow(text: item.text, met: item.met),
            if (item != items.last)
              SizedBox(height: a.of(AuroraSpacing.space3)),
          ],
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.text, required this.met});

  final String text;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final dot = a.of(AuroraAuthSizes.ruleDot);
    return Semantics(
      checked: met,
      child: Row(
        children: [
          Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: met ? AuroraColors.olive : AuroraStructure.transparent,
              border: met
                  ? null
                  : Border.all(
                      color: AuroraColors.inkCheckBorder,
                      width: AuroraBorders.emphasis,
                    ),
            ),
            child: met
                ? Icon(
                    CupertinoIcons.check_mark,
                    size: a.of(AuroraAuthSizes.ruleCheck),
                    color: AuroraColors.lime,
                  )
                : null,
          ),
          SizedBox(width: a.of(AuroraSpacing.space3)),
          Expanded(
            child: Text(
              text,
              style: AuroraAuthType.rule.copyWith(
                color: met ? AuroraColors.ink : AuroraColors.inkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
