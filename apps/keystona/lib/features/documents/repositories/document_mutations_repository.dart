import 'package:supabase_flutter/supabase_flutter.dart';

/// Removing a document and bringing it back.
///
/// Both go through database functions, never a plain UPDATE of `deleted_at`:
/// the row's SELECT policy hides soft-deleted rows, so a plain write is
/// rejected on delete (42501) and matches nothing on restore.
abstract interface class DocumentMutationsRepository {
  /// Soft-deletes the document. Throws when it is not the caller's.
  Future<void> softDelete(String documentId);

  /// Undoes [softDelete]. Throws when it is not the caller's or not deleted.
  Future<void> restore(String documentId);
}

/// Calls a database function by name with named parameters.
typedef RpcCall =
    Future<void> Function(String function, Map<String, dynamic> params);

class SupabaseDocumentMutationsRepository
    implements DocumentMutationsRepository {
  SupabaseDocumentMutationsRepository(this._rpc);

  /// Wires [RpcCall] to a real client.
  factory SupabaseDocumentMutationsRepository.client(SupabaseClient client) =>
      SupabaseDocumentMutationsRepository(
        (function, params) => client.rpc<void>(function, params: params),
      );

  final RpcCall _rpc;

  static const String softDeleteFunction = 'soft_delete_document';
  static const String restoreFunction = 'restore_document';
  static const String idParam = 'p_document_id';

  @override
  Future<void> softDelete(String documentId) =>
      _rpc(softDeleteFunction, {idParam: documentId});

  @override
  Future<void> restore(String documentId) =>
      _rpc(restoreFunction, {idParam: documentId});
}
