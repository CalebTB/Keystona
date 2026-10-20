import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../repositories/document_file_actions.dart';
import '../repositories/document_mutations_repository.dart';
import '../repositories/document_files_repository.dart';
import '../repositories/document_search_repository.dart';
import '../repositories/expiring_documents_repository.dart';

part 'document_repositories_provider.g.dart';

/// Data-access seams for the document detail, search and expiring screens.
/// Tests override these with fakes so nothing reaches Supabase.

@riverpod
DocumentSearchRepository documentSearchRepository(Ref ref) =>
    FallbackDocumentSearchRepository(
      fullText: SupabaseFullTextSearchRepository(SupabaseService.client),
      byName: SupabaseNameSearchRepository(SupabaseService.client),
    );

@riverpod
DocumentMutationsRepository documentMutationsRepository(Ref ref) =>
    SupabaseDocumentMutationsRepository.client(SupabaseService.client);

@riverpod
ExpiringDocumentsRepository expiringDocumentsRepository(Ref ref) =>
    SupabaseExpiringDocumentsRepository(SupabaseService.client);

@riverpod
DocumentFilesRepository documentFilesRepository(Ref ref) =>
    SupabaseDocumentFilesRepository(SupabaseService.client);

@riverpod
DocumentFileActions documentFileActions(Ref ref) =>
    const PluginDocumentFileActions();

/// Signed URL for a document thumbnail, or null when it cannot be created.
@riverpod
Future<String?> documentThumbnailUrl(Ref ref, String path) =>
    ref.watch(documentFilesRepositoryProvider).signedUrl(path);
