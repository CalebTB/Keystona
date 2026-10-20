/// One document on an `ItemDocumentsCard`.
class ItemDocumentRow {
  const ItemDocumentRow({
    required this.id,
    required this.title,
    required this.meta,
  });

  final String id;
  final String title;

  /// "WARRANTY · PDF · UNTIL MAR 2031".
  final String meta;
}
