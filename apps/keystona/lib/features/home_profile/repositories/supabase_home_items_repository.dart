import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/home_item.dart';
import 'home_item_mapper.dart';
import 'home_items_repository.dart';

/// [HomeItemsRepository] over Supabase. Items replaced or removed are left
/// out; they no longer have a life to track.
class SupabaseHomeItemsRepository implements HomeItemsRepository {
  const SupabaseHomeItemsRepository(this._client);

  final SupabaseClient _client;

  static const List<String> _inService = ['active', 'needs_repair'];

  @override
  Future<List<HomeItem>> fetchItems(String propertyId) async {
    final results = await Future.wait([
      _client
          .from('systems')
          .select(HomeItemMapper.systemColumns)
          .eq('property_id', propertyId)
          .inFilter('status', _inService)
          .isFilter('deleted_at', null),
      _client
          .from('appliances')
          .select(HomeItemMapper.applianceColumns)
          .eq('property_id', propertyId)
          .inFilter('status', _inService)
          .isFilter('deleted_at', null),
    ]);
    final now = DateTime.now();
    return [
      for (final row in results[0]) HomeItemMapper.system(row, now),
      for (final row in results[1]) HomeItemMapper.appliance(row, now),
    ];
  }
}
