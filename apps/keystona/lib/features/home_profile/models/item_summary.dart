import 'item_ref.dart';

/// The little a shared item screen needs to know about its system or
/// appliance: what to call it and the eyebrow line.
class ItemSummary {
  const ItemSummary({
    required this.item,
    required this.name,
    this.brand,
    this.model,
  });

  final ItemRef item;
  final String name;
  final String? brand;
  final String? model;

  /// "Northline NF95-080B", or null when neither is known.
  String? get brandModel {
    final parts = [brand, model]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' ');
  }

  /// "FURNACE · NORTHLINE NF95-080B", or just the name.
  String get eyebrow {
    final bm = brandModel;
    return (bm == null ? name : '$name · $bm').toUpperCase();
  }

  /// The name in running text: "furnace".
  String get lowerName => name.toLowerCase();
}
