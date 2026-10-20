/// What a search is looking for.
///
/// Value equality makes it a valid provider family key.
class DocumentSearchQuery {
  const DocumentSearchQuery({this.text = '', this.categoryId});

  /// Trimmed search text. Empty when only a category is chosen.
  final String text;

  /// Restricts results to one category. Null searches everything.
  final String? categoryId;

  bool get isEmpty => text.isEmpty && categoryId == null;

  @override
  bool operator ==(Object other) =>
      other is DocumentSearchQuery &&
      other.text == text &&
      other.categoryId == categoryId;

  @override
  int get hashCode => Object.hash(text, categoryId);
}

/// One row in the search results.
class DocumentSearchHit {
  const DocumentSearchHit({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.addedAt,
    this.expirationDate,
    this.snippet,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String categoryName;

  /// Date shown beside the category ("JAN 28").
  final DateTime addedAt;

  /// End date, when the document has one. Drives the status chip.
  final DateTime? expirationDate;

  /// Matched text from inside the file, with matches wrapped in `**`.
  /// Premium full-text search only.
  final String? snippet;

  /// The document's tags (`documents.tags`).
  final List<String> tags;
}
