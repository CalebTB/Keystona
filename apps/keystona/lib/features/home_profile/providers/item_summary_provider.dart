import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/item_ref.dart';
import '../models/item_summary.dart';
import '../repositories/item_summary_repository.dart';

part 'item_summary_provider.g.dart';

/// The data source behind [itemSummary]. Tests override it.
final itemSummaryRepositoryProvider = Provider<ItemSummaryRepository>(
  (ref) => SupabaseItemSummaryRepository(SupabaseService.client),
);

/// The name and brand of the system or appliance a shared item screen
/// (tasks, photos, reminders) belongs to. Null when it no longer exists.
@riverpod
Future<ItemSummary?> itemSummary(Ref ref, ItemRef item) =>
    ref.watch(itemSummaryRepositoryProvider).get(item);
