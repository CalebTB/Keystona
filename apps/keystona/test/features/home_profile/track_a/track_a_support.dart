import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:keystona/features/auth/providers/auth_provider.dart';
import 'package:keystona/features/home_profile/lifespan/lifespan_reading.dart';
import 'package:keystona/features/home_profile/models/home_item.dart';
import 'package:keystona/features/home_profile/models/item_ref.dart';
import 'package:keystona/features/home_profile/models/property.dart';
import 'package:keystona/features/home_profile/models/property_edits.dart';
import 'package:keystona/features/home_profile/providers/home_repositories.dart';
import 'package:keystona/features/home_profile/repositories/home_items_repository.dart';
import 'package:keystona/features/home_profile/repositories/property_repository.dart';
import 'package:keystona/features/maintenance/models/home_health_score.dart';
import 'package:keystona/features/maintenance/models/reminder_item.dart';
import 'package:keystona/features/maintenance/providers/home_health_score_provider.dart';
import 'package:keystona/features/maintenance/providers/reminders_providers.dart';

Property sampleProperty({
  String zip = '35758',
  String state = 'AL',
  String? type = 'single_family',
}) => Property(
  id: 'p1',
  userId: 'u1',
  addressLine1: '1428 Elm Hollow Ln',
  city: 'Springfield',
  state: state,
  zipCode: zip,
  propertyType: type,
  yearBuilt: 1998,
  squareFeet: 2140,
  lotSizeSqft: 13504,
  bedrooms: 4,
  bathrooms: 2.5,
  stories: 2,
  hasBasement: true,
  garageType: 'attached',
  garageSpaces: 2,
  purchaseDate: DateTime(2024, 3),
  purchasePrice: 318000,
  climateZone: 4,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

HomeItem item(
  String id,
  String name, {
  ItemKind kind = ItemKind.system,
  double age = 5,
  int life = 15,
  int? startYear,
  double? cost,
  String category = 'hvac',
}) => HomeItem(
  ref: ItemRef(kind, id),
  name: name,
  category: category,
  cost: cost,
  reading: LifespanReading.ofAge(
    ageYears: age,
    lifeYears: life,
    startYear: startYear ?? 2026 - age.floor(),
  ),
);

/// Items shaped like the kit: one past its life, one at the end, a few fine.
List<HomeItem> sampleItems() => [
  item(
    's1',
    'Water heater',
    age: 12,
    life: 12,
    cost: 1800,
    category: 'plumbing',
  ),
  item('s2', 'Furnace', age: 5.5, life: 15, cost: 5800),
  item('s3', 'Roof', age: 14, life: 25, cost: 14000, category: 'roofing'),
  item(
    'a1',
    'Dishwasher',
    kind: ItemKind.appliance,
    age: 11.5,
    life: 10,
    cost: 800,
    category: 'kitchen',
  ),
  item(
    'a2',
    'Washer',
    kind: ItemKind.appliance,
    age: 3,
    life: 11,
    cost: 1000,
    category: 'laundry',
  ),
];

class FakePropertyRepository implements PropertyRepository {
  FakePropertyRepository(this.property, {this.failSave = false});

  Property? property;
  bool failSave;
  Object? fetchError;
  final List<PropertyEdits> saved = [];

  @override
  Future<Property?> fetchProperty() async {
    if (fetchError != null) throw fetchError!;
    return property;
  }

  @override
  Future<String?> signedPhotoUrl(String path) async => null;

  @override
  Future<void> save(String propertyId, PropertyEdits edits) async {
    if (failSave) throw StateError('save failed');
    saved.add(edits);
  }
}

class FakeHomeItemsRepository implements HomeItemsRepository {
  FakeHomeItemsRepository(this.items);

  List<HomeItem> items;

  @override
  Future<List<HomeItem>> fetchItems(String propertyId) async => items;
}

class _FakeHealth extends HomeHealthScoreNotifier {
  @override
  Future<HomeHealthScore> build() async => const HomeHealthScore(
    score: 78,
    trend: 'stable',
    totalTasks: 10,
    completed: 8,
    overdue: 0,
    upcoming: 2,
  );
}

class _FakeReminders extends RemindersNotifier {
  @override
  Future<RemindersData> build() async => const RemindersData();
}

/// Overrides for the three data seams, plus health and reminders.
List<Override> homeOverrides(
  FakePropertyRepository property,
  FakeHomeItemsRepository items,
) => [
  isAuthenticatedProvider.overrideWithValue(true),
  propertyRepositoryProvider.overrideWithValue(property),
  homeItemsRepositoryProvider.overrideWithValue(items),
  homeHealthScoreProvider.overrideWith(_FakeHealth.new),
  remindersProvider.overrideWith(_FakeReminders.new),
];
