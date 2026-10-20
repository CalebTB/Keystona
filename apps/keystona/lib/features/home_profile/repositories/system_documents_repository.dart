import '../models/system_document.dart';

/// Documents that belong to a system: the ones linked to it, and its
/// warranty document. Read only.
abstract interface class SystemDocumentsRepository {
  /// Newest first. [warrantyDocId] is the system's `linked_warranty_doc_id`.
  Future<List<SystemDocument>> forSystem(
    String systemId, {
    String? warrantyDocId,
  });
}
