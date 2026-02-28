import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/document_type.dart';

part 'document_types_provider.g.dart';

/// Loads all document types that belong to [categoryId], sorted by [sortOrder].
///
/// Used by the upload wizard category step to show type sub-selection after
/// the user picks a category.
@riverpod
Future<List<DocumentType>> documentTypes(
  Ref ref,
  String categoryId,
) async {
  final response = await SupabaseService.client
      .from('document_types')
      .select('id, category_id, name, description, metadata_schema, sort_order')
      .eq('category_id', categoryId)
      .order('sort_order');

  return response.map((json) => DocumentType.fromJson(json)).toList();
}
