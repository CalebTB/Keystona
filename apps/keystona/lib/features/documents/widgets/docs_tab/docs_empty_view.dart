import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../docs_copy.dart';
import 'docs_suggestion_row.dart';

/// The empty vault (kit: DocsEmpty): one clear action, then three documents
/// worth adding first.
class DocsEmptyView extends StatelessWidget {
  const DocsEmptyView({
    super.key,
    required this.onAdd,
    required this.onScan,
    required this.onSuggestion,
  });

  final VoidCallback onAdd;
  final VoidCallback onScan;
  final VoidCallback onSuggestion;

  static const List<IconData> _suggestionIcons = [
    Icons.shield_outlined,
    Icons.home_outlined,
    Icons.workspace_premium_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(onAdd: onAdd, onScan: onScan),
        SizedBox(height: a.of(AuroraSpacing.space9)),
        Text(DocsCopy.startWith, style: AuroraType.label),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AuroraRadius.xl,
            border: Border.all(
              color: AuroraColors.inkBorder,
              width: AuroraBorders.regular,
            ),
          ),
          child: ClipRRect(
            borderRadius: AuroraRadius.xl,
            child: Column(
              children: [
                for (var i = 0; i < DocsCopy.suggestions.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: EdgeInsets.only(
                        left: a.of(AuroraDocsA.suggestionInset),
                      ),
                      child: const Divider(
                        height: AuroraBorders.hairline,
                        thickness: AuroraBorders.hairline,
                        color: AuroraColors.inkBorder,
                      ),
                    ),
                  DocsSuggestionRow(
                    icon: _suggestionIcons[i],
                    title: DocsCopy.suggestions[i].title,
                    meta: DocsCopy.suggestions[i].meta,
                    onTap: onSuggestion,
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Padding(
          padding: a.symmetric(horizontal: AuroraDocsA.hairlineGap),
          child: Text(
            DocsCopy.emptyFootnote,
            style: AuroraType.bodySm.copyWith(color: AuroraColors.inkSecondary),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onAdd, required this.onScan});

  final VoidCallback onAdd;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Padding(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space5,
        vertical: AuroraSpacing.space10,
      ),
      child: Column(
        children: [
          Container(
            width: a.of(AuroraSharedSizes.emptyIconCircle),
            height: a.of(AuroraSharedSizes.emptyIconCircle),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AuroraColors.coral,
                width: AuroraBorders.emphasis,
              ),
            ),
            child: ExcludeSemantics(
              child: Icon(
                Icons.note_add_outlined,
                size: a.of(AuroraSharedSizes.emptyIconGlyph),
                color: AuroraColors.coral,
              ),
            ),
          ),
          SizedBox(height: a.of(AuroraSpacing.space6)),
          Text(
            DocsCopy.emptyTitle,
            textAlign: TextAlign.center,
            style: AuroraDocsAType.heroTitle,
          ),
          SizedBox(height: a.of(AuroraSpacing.space6)),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: a.of(AuroraSharedSizes.bodyMaxWidth),
            ),
            child: Text(
              DocsCopy.emptyBody,
              textAlign: TextAlign.center,
              style: AuroraDocsAType.emptyBody,
            ),
          ),
          SizedBox(height: a.of(AuroraSpacing.space8)),
          PrimaryButton(
            label: DocsCopy.addDocument,
            onPressed: onAdd,
            expand: true,
            tone: AuroraButtonTone.coral,
          ),
          SizedBox(height: a.of(AuroraSpacing.space3)),
          SecondaryButton(
            label: DocsCopy.scanWithCamera,
            onPressed: onScan,
            expand: true,
          ),
        ],
      ),
    );
  }
}
