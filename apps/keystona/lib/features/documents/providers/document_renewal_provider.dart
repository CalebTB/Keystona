import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/renewal_source.dart';
import '../services/document_renewal_repository.dart';

part 'document_renewal_provider.g.dart';

/// Reads and marks the document being renewed. Override in tests so nothing
/// reaches Supabase.
@Riverpod(keepAlive: true)
DocumentRenewalRepository documentRenewalRepository(Ref ref) =>
    const SupabaseDocumentRenewalRepository();

/// What the renewal form starts from, for the document with [documentId].
@riverpod
Future<RenewalSource> renewalSource(Ref ref, String documentId) =>
    ref.watch(documentRenewalRepositoryProvider).load(documentId);
