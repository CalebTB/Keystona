import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expiring_document.dart';
import 'current_property.dart';

/// Data access for the Expiring screen.
abstract interface class ExpiringDocumentsRepository {
  /// Every document with an end date, soonest first (past dates included).
  Future<List<ExpiringDocument>> fetch();
}

class SupabaseExpiringDocumentsRepository
    implements ExpiringDocumentsRepository {
  SupabaseExpiringDocumentsRepository(this._client);

  final SupabaseClient _client;

  /// Metadata keys that may carry the issuer, in order of preference.
  static const List<String> providerKeys = [
    'provider',
    'issuer',
    'insurer',
    'carrier',
    'company',
    'vendor',
  ];

  /// Fallback icon key when a category has none.
  static const String _fallbackIcon = 'document';

  @override
  Future<List<ExpiringDocument>> fetch() async {
    final propertyId = await currentPropertyId(_client);
    if (propertyId == null) return const [];

    final rows = await _client
        .from('documents')
        .select(
          'id, name, expiration_date, metadata, '
          'category:document_categories(name, icon)',
        )
        .eq('property_id', propertyId)
        .isFilter('deleted_at', null)
        .not('expiration_date', 'is', null)
        .order('expiration_date', ascending: true);

    return rows.map(_map).toList();
  }

  ExpiringDocument _map(Map<String, dynamic> row) {
    final category = row['category'] as Map<String, dynamic>?;
    final metadata = (row['metadata'] as Map<String, dynamic>?) ?? const {};
    return ExpiringDocument(
      id: row['id'] as String,
      name: row['name'] as String,
      categoryName: (category?['name'] as String?) ?? '',
      categoryIcon: (category?['icon'] as String?) ?? _fallbackIcon,
      expirationDate: DateTime.parse(row['expiration_date'] as String),
      provider: _providerOf(metadata),
    );
  }

  static String? _providerOf(Map<String, dynamic> metadata) {
    for (final key in providerKeys) {
      final value = metadata[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
