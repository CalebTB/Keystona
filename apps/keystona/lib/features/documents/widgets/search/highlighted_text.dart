import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_sizes.dart';
import '../../models/search_highlight.dart';

/// Text with its matched part in bold and underlined.
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.spans,
    required this.style,
    this.maxLines,
    this.underline = true,
  });

  final List<HighlightSpan> spans;
  final TextStyle style;
  final int? maxLines;

  /// Underline the matched run (names). Snippets use bold only.
  final bool underline;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          for (final span in spans)
            TextSpan(
              text: span.text,
              style: span.bold
                  ? TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: underline ? TextDecoration.underline : null,
                      decorationThickness: AuroraBorders.emphasis,
                    )
                  : null,
            ),
        ],
      ),
      style: style,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
