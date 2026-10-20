import 'document.dart';

/// Rules and reading for a document's tags (the `documents.tags` column).
abstract final class DocumentTags {
  /// Metadata key older rows kept their tags under, before the column existed.
  static const String legacyMetadataKey = 'tags';

  /// A tag as typed: no leading '#', commas turned into spaces, trimmed.
  static String clean(String raw) =>
      raw.trim().replaceFirst(RegExp(r'^#+'), '').replaceAll(',', ' ').trim();

  /// [current] with [raw] added, or null when it is refused: blank, longer
  /// than [maxLength], a repeat (any case), or [current] already holds [max].
  static List<String>? adding(
    List<String> current,
    String raw, {
    required int max,
    required int maxLength,
  }) {
    final tag = clean(raw);
    final duplicate = current.any((t) => t.toLowerCase() == tag.toLowerCase());
    if (tag.isEmpty || tag.length > maxLength || duplicate) return null;
    if (current.length >= max) return null;
    return [...current, tag];
  }

  /// Tags for display: the column, or an old row's `metadata['tags']` list
  /// when the column is empty. Cleaned, blanks dropped.
  static List<String> of(Document document) => fromRow(
        document.tags,
        document.metadata[legacyMetadataKey],
      );

  /// Same rule for raw row values ([column] may be null or any list).
  static List<String> fromRow(Object? column, [Object? legacy]) {
    final fromColumn = _clean(column);
    return fromColumn.isNotEmpty ? fromColumn : _clean(legacy);
  }

  static List<String> _clean(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final t in raw)
        if (clean(t.toString()).isNotEmpty) clean(t.toString()),
    ];
  }
}
