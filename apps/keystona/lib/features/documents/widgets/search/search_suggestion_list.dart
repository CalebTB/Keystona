import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../models/category_icons.dart';
import '../shared/docs_section_header.dart';

/// One category offered under "Search in".
class SearchSuggestion {
  const SearchSuggestion({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.count,
  });

  final String id;
  final String name;
  final String iconKey;
  final int count;
}

/// "Search in": the categories as one list card, each with its document
/// count. Tapping one scopes the search to it.
class SearchSuggestionList extends StatelessWidget {
  const SearchSuggestionList({
    super.key,
    required this.suggestions,
    required this.onPick,
  });

  final List<SearchSuggestion> suggestions;
  final ValueChanged<SearchSuggestion> onPick;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DocsSectionHeader(title: 'Search in'),
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
                for (var i = 0; i < suggestions.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: AuroraBorders.hairline,
                      thickness: AuroraBorders.hairline,
                      color: AuroraColors.inkBorder,
                    ),
                  _SuggestionRow(
                    suggestion: suggestions[i],
                    onTap: () => onPick(suggestions[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestion, required this.onTap});

  final SearchSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: '${suggestion.name}, ${suggestion.count}',
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraDocsCSizes.suggestionRowMinHeight),
        ),
        child: Padding(
          padding: a.symmetric(horizontal: AuroraSpacing.space6),
          child: Row(
            children: [
              Icon(
                CategoryIcons.forKey(suggestion.iconKey),
                size: a.of(AuroraIconSizes.xl),
                color: AuroraColors.inkSubtle,
              ),
              SizedBox(width: a.of(AuroraSpacing.space5)),
              Expanded(
                child: Text(
                  suggestion.name,
                  style: AuroraType.button.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(width: a.of(AuroraSpacing.space3)),
              Text(
                '${suggestion.count}',
                style: AuroraType.number.copyWith(
                  fontWeight: FontWeight.w400,
                  color: AuroraColors.inkHelper,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
