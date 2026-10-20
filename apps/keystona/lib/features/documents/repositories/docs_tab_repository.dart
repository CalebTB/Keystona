import '../../../services/supabase_service.dart';
import '../models/docs_tab_data.dart';

/// Data access for the Docs tab.
abstract interface class DocsTabRepository {
  /// Loads everything the tab shows. Returns empty data when there is no
  /// signed-in user or no property yet.
  Future<DocsTabData> load();

  /// Schedules a renewal reminder for the document [documentId].
  Future<void> scheduleRenewalReminder(String documentId);
}

/// Supabase-backed [DocsTabRepository].
///
/// Every query filters by `property_id` first, skips soft-deleted rows and
/// selects only the columns the tab needs.
class SupabaseDocsTabRepository implements DocsTabRepository {
  const SupabaseDocsTabRepository();

  /// How many documents "Recently added" lists.
  static const int recentLimit = 5;

  static const String _itemColumns =
      'id, name, created_at, expiration_date, '
      'category:document_categories(name, icon)';

  @override
  Future<DocsTabData> load() async {
    final client = SupabaseService.client;
    final user = client.auth.currentUser;
    if (user == null) return const DocsTabData();

    final property = await client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (property == null) return const DocsTabData();
    final propertyId = property['id'] as String;

    final results = await Future.wait([
      client
          .from('documents')
          .select(_itemColumns)
          .eq('property_id', propertyId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(recentLimit),
      client
          .from('documents')
          .select(_itemColumns)
          .eq('property_id', propertyId)
          .isFilter('deleted_at', null)
          .not('expiration_date', 'is', null)
          .order('expiration_date', ascending: true),
      client
          .from('documents')
          .select('category_id')
          .eq('property_id', propertyId)
          .isFilter('deleted_at', null),
      client
          .from('document_categories')
          .select('id, name')
          .eq('is_system', true)
          .order('sort_order'),
    ]);

    final used = <String>{
      for (final row in results[2]) row['category_id'] as String,
    };
    return DocsTabData(
      totalCount: results[2].length,
      recent: results[0].map(_item).toList(),
      expiring: results[1].map(_item).toList(),
      emptyCategoryNames: [
        for (final row in results[3])
          if (!used.contains(row['id'])) row['name'] as String,
      ],
    );
  }

  @override
  Future<void> scheduleRenewalReminder(String documentId) {
    throw UnimplementedError(
      'scheduleRenewalReminder() implemented by issue #24',
    );
  }

  DocsTabItem _item(Map<String, dynamic> row) {
    final category = row['category'] as Map<String, dynamic>?;
    final expires = row['expiration_date'] as String?;
    return DocsTabItem(
      id: row['id'] as String,
      name: row['name'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      categoryName: category?['name'] as String?,
      categoryIcon: category?['icon'] as String?,
      expirationDate: expires == null ? null : DateTime.parse(expires),
    );
  }
}
