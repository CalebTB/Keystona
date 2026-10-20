/// How a renewal is carried and remembered, with no schema change.
///
/// The add-document route is opened with the id of the document being
/// renewed in [queryParam]. When the new document is saved, the old one is
/// marked replaced by two keys in its `metadata` JSONB: [replacedAtKey]
/// (`YYYY-MM-DD`) and [replacedByKey] (the new document's id). The old
/// document is kept.
abstract final class DocumentRenewal {
  /// Query parameter on the add-document route: `?renew=<documentId>`.
  static const String queryParam = 'renew';

  /// Metadata key: the day the document was replaced, `YYYY-MM-DD`.
  static const String replacedAtKey = 'replaced_at';

  /// Metadata key: the id of the document that replaced this one.
  static const String replacedByKey = 'replaced_by';

  /// The add-document location, in renewal mode for [documentId].
  static String location(String uploadPath, String documentId) => Uri(
    path: uploadPath,
    queryParameters: {queryParam: documentId},
  ).toString();

  /// When the document was replaced, or null when it has not been.
  static DateTime? replacedAt(Map<String, dynamic>? metadata) {
    final raw = metadata?[replacedAtKey];
    return raw is String ? DateTime.tryParse(raw) : null;
  }

  /// The id of the newer document, or null when none is recorded.
  static String? replacedBy(Map<String, dynamic>? metadata) {
    final raw = metadata?[replacedByKey];
    return raw is String && raw.isNotEmpty ? raw : null;
  }

  /// [metadata] with the replaced keys added. Every other key is kept.
  static Map<String, dynamic> withReplaced(
    Map<String, dynamic>? metadata, {
    required DateTime on,
    required String by,
  }) => {
    ...?metadata,
    replacedAtKey: _dateOnly(on),
    replacedByKey: by,
  };

  /// DATE-style `YYYY-MM-DD`, never a full timestamp.
  static String _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;
}
