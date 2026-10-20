import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/expiring_document.dart';
import 'document_repositories_provider.dart';

part 'expiring_documents_provider.g.dart';

/// Every document with an end date, soonest first. Invalidated by the detail
/// screen after an edit, delete or undo so the list never goes stale.
@riverpod
Future<List<ExpiringDocument>> expiringDocuments(Ref ref) =>
    ref.watch(expiringDocumentsRepositoryProvider).fetch();
