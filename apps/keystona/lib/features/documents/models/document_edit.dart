/// The fields the edit sheet can change on a document.
class DocumentEdit {
  const DocumentEdit({
    required this.name,
    required this.categoryId,
    this.expirationDate,
    this.notes,
  });

  final String name;
  final String categoryId;

  /// Null removes the end date.
  final DateTime? expirationDate;

  /// Null removes the notes.
  final String? notes;

  /// Column map for the `documents` update. `expiration_date` is a DATE
  /// column, so it is sent as `YYYY-MM-DD`, never a full timestamp.
  Map<String, dynamic> toChanges() => {
        'name': name,
        'category_id': categoryId,
        'expiration_date': expirationDate == null
            ? null
            : _dateOnly(expirationDate!),
        'notes': notes,
      };

  static String _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;
}
