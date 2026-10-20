/// A run of text, bold when it matched the search.
class HighlightSpan {
  const HighlightSpan(this.text, {this.bold = false});

  final String text;
  final bool bold;
}

/// Pure helpers that mark where a search matched.
abstract final class SearchHighlight {
  /// Marker the full-text RPC wraps around matched terms.
  static const String marker = '**';

  /// Splits [text] around the first case-insensitive occurrence of [query].
  /// Without a query or a match it returns the whole text unmarked.
  static List<HighlightSpan> name(String text, String query) {
    final needle = query.trim();
    if (needle.isEmpty) return [HighlightSpan(text)];
    final at = text.toLowerCase().indexOf(needle.toLowerCase());
    if (at < 0) return [HighlightSpan(text)];
    final end = at + needle.length;
    return [
      if (at > 0) HighlightSpan(text.substring(0, at)),
      HighlightSpan(text.substring(at, end), bold: true),
      if (end < text.length) HighlightSpan(text.substring(end)),
    ];
  }

  /// Turns a `**match**` snippet from the full-text RPC into spans.
  static List<HighlightSpan> snippet(String snippet) {
    final parts = snippet.split(marker);
    return [
      for (var i = 0; i < parts.length; i++)
        if (parts[i].isNotEmpty) HighlightSpan(parts[i], bold: i.isOdd),
    ];
  }
}
