/// A document in Docs that belongs to a system or appliance.
class ItemDocument {
  const ItemDocument({
    required this.id,
    required this.name,
    required this.createdAt,
    this.typeName,
    this.mimeType,
    this.pageCount,
    this.expirationDate,
  });

  /// Reads a row from `documents` with its `type:document_types(name)`.
  factory ItemDocument.fromRow(Map<String, dynamic> row) {
    final type = row['type'] as Map<String, dynamic>?;
    return ItemDocument(
      id: row['id'] as String,
      name: row['name'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      typeName: type?['name'] as String?,
      mimeType: row['mime_type'] as String?,
      pageCount: (row['page_count'] as num?)?.toInt(),
      expirationDate: DateTime.tryParse(
        row['expiration_date'] as String? ?? '',
      ),
    );
  }

  final String id;
  final String name;
  final DateTime createdAt;
  final String? typeName;
  final String? mimeType;
  final int? pageCount;
  final DateTime? expirationDate;
}
