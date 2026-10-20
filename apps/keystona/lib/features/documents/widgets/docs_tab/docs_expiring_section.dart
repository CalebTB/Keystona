import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_a.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../docs_copy.dart';
import '../../models/docs_tab_data.dart';
import 'docs_expiring_card.dart';
import 'pulse_dot.dart';

/// "EXPIRING SOON": the document that needs action first (when something is
/// due within 30 days) and a link to every expiring date.
class DocsExpiringSection extends StatelessWidget {
  const DocsExpiringSection({
    super.key,
    required this.soon,
    required this.expiryCount,
    required this.showCard,
    required this.onUploadRenewal,
    required this.onRemind,
    required this.onOpen,
    required this.onSeeAllExpiring,
  });

  /// Documents expiring within 90 days, soonest first.
  final List<DocsTabItem> soon;

  /// Documents with any expiration date.
  final int expiryCount;

  /// False when nothing is urgent: only the "All expiring dates" link shows.
  final bool showCard;

  final ValueChanged<DocsTabItem> onUploadRenewal;
  final ValueChanged<DocsTabItem> onRemind;
  final ValueChanged<DocsTabItem> onOpen;
  final VoidCallback onSeeAllExpiring;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final hero = showCard && soon.isNotEmpty ? soon.first : null;
    final next = soon.length > 1 ? soon[1] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hero != null) ...[
          Row(
            children: [
              const PulseDot(),
              SizedBox(width: a.of(AuroraSpacing.space2)),
              Expanded(
                child: Text(
                  DocsCopy.expiringHeader,
                  style: AuroraType.sectionTitle.copyWith(
                    color: AuroraColors.coralDeep,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: a.of(AuroraSpacing.space3)),
          DocsExpiringCard(
            item: hero,
            more: soon.length - 1,
            next: next,
            onUploadRenewal: () => onUploadRenewal(hero),
            onRemind: () => onRemind(hero),
            onOpenNext: next == null ? null : () => onOpen(next),
          ),
        ],
        if (expiryCount > 0)
          _AllExpiringLink(count: expiryCount, onTap: onSeeAllExpiring),
      ],
    );
  }
}

class _AllExpiringLink extends StatelessWidget {
  const _AllExpiringLink({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final label = DocsCopy.allExpiring(count);
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraSizes.minTouch),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AuroraDocsAType.link.copyWith(
                  color: AuroraColors.inkSubtle,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: a.of(AuroraIconSizes.sm),
              color: AuroraColors.inkCheckBorder,
            ),
          ],
        ),
      ),
    );
  }
}
