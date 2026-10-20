import '../lifespan/lifespan_reading.dart';
import 'item_ref.dart';

/// One system or appliance as the Home profile overview and lifespan screens
/// need it: a name, what it is, how old it is against its life, and what it
/// would cost to replace. Read through the track A repository, never through
/// the systems or appliances providers.
class HomeItem {
  const HomeItem({
    required this.ref,
    required this.name,
    required this.category,
    required this.reading,
    this.subtitle,
    this.cost,
  });

  final ItemRef ref;
  final String name;

  /// The database category value ("hvac", "kitchen"). Picks the icon.
  final String category;

  /// "model · location", when either is known.
  final String? subtitle;
  final LifespanReading reading;

  /// `estimated_replacement_cost`, null when not set.
  final double? cost;

  bool get isSystem => ref.isSystem;
}
