import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/providers/service_providers.dart';
import '../models/document_search_hit.dart';
import 'document_repositories_provider.dart';

part 'document_search_provider.g.dart';

/// Search results for [query]. Premium accounts also search inside files.
///
/// The screen debounces typing (300 ms) before it builds a query, so this
/// provider never fires per keystroke.
@riverpod
Future<List<DocumentSearchHit>> documentSearch(
  Ref ref,
  DocumentSearchQuery query,
) {
  if (query.isEmpty) return Future.value(const []);
  final fullText = ref.watch(isPremiumProvider);
  return ref
      .watch(documentSearchRepositoryProvider)
      .search(query, fullText: fullText);
}
