import '../lifespan/lifespan_reading.dart';
import '../models/home_item.dart';
import '../models/item_ref.dart';

/// Turns database rows into [HomeItem]s. Pure, so it is tested directly.
abstract final class HomeItemMapper {
  /// Columns read from `systems`.
  static const String systemColumns =
      'id, category, name, model, location, installation_date, '
      'expected_lifespan_min, expected_lifespan_max, lifespan_override, '
      'estimated_replacement_cost';

  /// Columns read from `appliances`.
  static const String applianceColumns =
      'id, category, name, model, location, purchase_date, '
      'expected_lifespan_min, expected_lifespan_max, lifespan_override, '
      'estimated_replacement_cost';

  /// A system ages from its installation date.
  static HomeItem system(Map<String, dynamic> row, DateTime now) =>
      _item(row, ItemKind.system, 'installation_date', now);

  /// An appliance ages from its purchase date.
  static HomeItem appliance(Map<String, dynamic> row, DateTime now) =>
      _item(row, ItemKind.appliance, 'purchase_date', now);

  static HomeItem _item(
    Map<String, dynamic> row,
    ItemKind kind,
    String startColumn,
    DateTime now,
  ) {
    final start = DateTime.tryParse((row[startColumn] as String?) ?? '');
    final model = _clean(row['model']);
    final location = _clean(row['location']);
    return HomeItem(
      ref: ItemRef(kind, row['id'] as String),
      name: (row['name'] as String?) ?? '',
      category: (row['category'] as String?) ?? 'other',
      subtitle: [?model, ?location].isEmpty
          ? null
          : [?model, ?location].join(' · '),
      cost: (row['estimated_replacement_cost'] as num?)?.toDouble(),
      reading: LifespanReading.from(
        start: start,
        min: (row['expected_lifespan_min'] as num?)?.toInt(),
        max: (row['expected_lifespan_max'] as num?)?.toInt(),
        override: (row['lifespan_override'] as num?)?.toInt(),
        now: now,
      ),
    );
  }

  static String? _clean(Object? value) {
    final text = (value as String?)?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
