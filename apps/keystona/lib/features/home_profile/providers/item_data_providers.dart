import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/item_completion.dart';
import '../models/item_document.dart';
import '../models/item_ref.dart';
import '../repositories/item_completions_repository.dart';
import '../repositories/item_documents_repository.dart';

part 'item_data_providers.g.dart';

/// The data sources behind the item screens' Done tab and Documents card.
/// Tests override them.
final itemCompletionsRepositoryProvider = Provider<ItemCompletionsRepository>(
  (ref) => SupabaseItemCompletionsRepository(SupabaseService.client),
);

final itemDocumentsRepositoryProvider = Provider<ItemDocumentsRepository>(
  (ref) => SupabaseItemDocumentsRepository(SupabaseService.client),
);

/// Finished tasks of a system or appliance, newest first.
@riverpod
Future<List<ItemCompletion>> itemCompletions(Ref ref, ItemRef item) =>
    ref.watch(itemCompletionsRepositoryProvider).list(item);

/// A request for an item's documents: the item and its linked warranty
/// document, when it has one. Value equality so it keys the provider.
class ItemDocumentsQuery {
  const ItemDocumentsQuery(this.item, {this.warrantyDocId});

  final ItemRef item;
  final String? warrantyDocId;

  @override
  bool operator ==(Object other) =>
      other is ItemDocumentsQuery &&
      other.item == item &&
      other.warrantyDocId == warrantyDocId;

  @override
  int get hashCode => Object.hash(item, warrantyDocId);
}

/// Documents in Docs that belong to a system or appliance.
@riverpod
Future<List<ItemDocument>> itemDocuments(Ref ref, ItemDocumentsQuery query) =>
    ref
        .watch(itemDocumentsRepositoryProvider)
        .list(query.item, warrantyDocId: query.warrantyDocId);
