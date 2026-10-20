/// A document linked to a system, as the detail "DOCUMENTS" card needs it.
class SystemDocument {
  const SystemDocument({
    required this.id,
    required this.name,
    required this.createdAt,
    this.categoryName,
    this.mimeType,
    this.expirationDate,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String? categoryName;
  final String? mimeType;
  final DateTime? expirationDate;
}
