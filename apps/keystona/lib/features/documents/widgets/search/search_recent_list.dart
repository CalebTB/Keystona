import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../shared/docs_section_header.dart';

/// "Recent": earlier searches, newest first. Tapping one searches it again.
class SearchRecentList extends StatelessWidget {
  const SearchRecentList({
    super.key,
    required this.searches,
    required this.onPick,
  });

  final List<String> searches;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DocsSectionHeader(title: 'Recent'),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        for (final text in searches)
          AuroraPressable(
            onTap: () => onPick(text),
            semanticLabel: 'Search again for $text',
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: a.minControl(AuroraSizes.minTouch),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: a.of(AuroraIconSizes.xl),
                    color: AuroraColors.inkPlaceholder,
                  ),
                  SizedBox(width: a.of(AuroraSpacing.space5)),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AuroraType.button.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
