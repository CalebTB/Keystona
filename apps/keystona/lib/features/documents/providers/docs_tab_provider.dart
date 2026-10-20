import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/docs_tab_data.dart';
import '../repositories/docs_tab_repository.dart';

part 'docs_tab_provider.g.dart';

/// The repository behind the Docs tab. Tests override this with a fake so
/// nothing reaches Supabase.
@riverpod
DocsTabRepository docsTabRepository(Ref ref) =>
    const SupabaseDocsTabRepository();

/// Everything the Docs tab shows: counts, recent and expiring documents.
///
/// Invalidated by [DocumentsNotifier] after any change to documents.
@riverpod
Future<DocsTabData> docsTab(Ref ref) =>
    ref.watch(docsTabRepositoryProvider).load();
