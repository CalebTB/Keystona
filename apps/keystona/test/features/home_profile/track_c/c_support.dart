import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/features/home_profile/models/appliance.dart';
import 'package:keystona/features/home_profile/models/item_completion.dart';
import 'package:keystona/features/home_profile/models/item_document.dart';
import 'package:keystona/features/home_profile/models/item_photo.dart';
import 'package:keystona/features/home_profile/models/item_photo_type.dart';
import 'package:keystona/features/home_profile/models/item_ref.dart';
import 'package:keystona/features/home_profile/models/item_summary.dart';
import 'package:keystona/features/home_profile/providers/appliances_provider.dart';
import 'package:keystona/features/home_profile/providers/item_data_providers.dart';
import 'package:keystona/features/home_profile/providers/item_photos_provider.dart';
import 'package:keystona/features/home_profile/providers/item_service_log_provider.dart';
import 'package:keystona/features/home_profile/providers/item_summary_provider.dart';
import 'package:keystona/features/home_profile/repositories/appliances_repository.dart';
import 'package:keystona/features/home_profile/repositories/item_completions_repository.dart';
import 'package:keystona/features/home_profile/repositories/item_documents_repository.dart';
import 'package:keystona/features/home_profile/repositories/item_photos_repository.dart';
import 'package:keystona/features/home_profile/repositories/item_summary_repository.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/services/providers/service_providers.dart';

import '../../maintenance/tab/tasks_test_support.dart';
import '../support/fake_item_service_log_repository.dart';

export '../../maintenance/tab/tasks_test_support.dart'
    show
        FakeMaintenanceTasksRepository,
        day,
        tallSurface,
        kToday,
        phoneSurface,
        settle,
        task,
        tasksOverrides;

// ─── Fixtures (dates are relative to kToday, 2026-10-04) ──────────────────────

Appliance anAppliance(
  String id,
  String name, {
  ApplianceCategory category = ApplianceCategory.kitchen,
  String? purchaseDate,
  int? life,
  String? brand,
  String? model,
  String? location,
  String? warrantyEnds,
  String? warrantyProvider,
  double? price,
  String? retailer,
  String? serial,
  String? color,
  Map<String, dynamic>? specs,
  ItemStatus status = ItemStatus.active,
  String? warrantyDoc,
}) => Appliance(
  id: id,
  propertyId: 'p1',
  userId: 'u1',
  category: category,
  name: name,
  status: status,
  brand: brand,
  modelNumber: model,
  location: location,
  purchaseDate: purchaseDate,
  expectedLifespanMin: life,
  expectedLifespanMax: life,
  warrantyExpiration: warrantyEnds,
  warrantyProvider: warrantyProvider,
  purchasePrice: price,
  retailer: retailer,
  serialNumber: serial,
  color: color,
  specifications: specs,
  linkedWarrantyDocId: warrantyDoc,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

/// The kit's HomeAppliances list: one past its life, a warranty about to end.
List<Appliance> kitAppliances() => [
  anAppliance(
    'dw',
    'Dishwasher',
    purchaseDate: '2015-04-01',
    life: 10,
    brand: 'Brennan',
    model: 'DW24',
    location: 'Kitchen',
  ),
  anAppliance(
    'fr',
    'Refrigerator',
    purchaseDate: '2017-04-01',
    life: 13,
    brand: 'Brennan',
    model: 'FR36-SxS',
    location: 'Kitchen',
  ),
  anAppliance(
    'rg',
    'Range',
    purchaseDate: '2017-04-01',
    life: 15,
    brand: 'Brennan',
    model: 'GR30 gas',
    location: 'Kitchen',
  ),
  anAppliance(
    'wa',
    'Washer',
    category: ApplianceCategory.laundry,
    purchaseDate: '2023-12-09',
    life: 11,
    brand: 'Halden',
    model: 'HW45-FL2',
    location: 'Laundry room',
    warrantyEnds: '2026-12-09',
    warrantyProvider: 'Halden + Brightway Care',
    price: 849,
    retailer: 'Brightway Appliance',
    serial: 'HL3390218K',
    color: 'White',
    specs: {
      'capacity': '4.5 cu ft',
      'type': 'Front-load',
      'spin_speed': '1,300 RPM',
      'hookup': 'Hot + cold · 120 V',
      'energy_star': true,
    },
  ),
  anAppliance(
    'dr',
    'Dryer',
    category: ApplianceCategory.laundry,
    purchaseDate: '2023-12-09',
    life: 13,
    brand: 'Halden',
    model: 'HD45-E',
    location: 'Laundry room',
  ),
];

ItemPhoto aPhoto(
  String id, {
  String? applianceId = 'wa',
  String? systemId,
  String type = 'unit',
  String? caption,
}) => ItemPhoto(
  id: id,
  userId: 'u1',
  applianceId: systemId == null ? applianceId : null,
  systemId: systemId,
  filePath: 'u1/p1/${applianceId ?? systemId}/$id.jpg',
  photoType: type,
  caption: caption,
  createdAt: DateTime(2026, 9, 10),
);

// ─── Fakes ────────────────────────────────────────────────────────────────────

class FakeAppliancesRepository implements AppliancesRepository {
  FakeAppliancesRepository(
    List<Appliance> items, {
    this.address = '1428 Elm Hollow Ln',
    this.gate,
  }) : items = [...items];

  final List<Appliance> items;
  final String? address;
  final Completer<void>? gate;
  Object? listError;
  Object? writeError;

  final List<Map<String, dynamic>> added = [];
  final List<({String id, Map<String, dynamic> fields})> updated = [];
  final List<String> deleted = [];
  final List<String> restored = [];
  final List<String> removedFromList = [];
  int lists = 0;

  @override
  Future<List<Appliance>> list() async {
    lists++;
    if (gate != null) await gate!.future;
    if (listError != null) throw listError!;
    return [...items];
  }

  @override
  Future<Appliance?> get(String id) async {
    if (listError != null) throw listError!;
    return items.where((a) => a.id == id).firstOrNull;
  }

  @override
  Future<String> add(Map<String, dynamic> fields) async {
    if (writeError != null) throw writeError!;
    added.add(fields);
    final id = 'new${added.length}';
    items.add(
      anAppliance(id, fields['name'] as String).copyWith(
        category: ApplianceCategory.values.firstWhere(
          (c) => c.value == fields['category'],
        ),
      ),
    );
    return id;
  }

  @override
  Future<void> update(String id, Map<String, dynamic> fields) async {
    if (writeError != null) throw writeError!;
    updated.add((id: id, fields: fields));
  }

  @override
  Future<void> softDelete(String id) async {
    if (writeError != null) throw writeError!;
    deleted.add(id);
    removedFromList.add(id);
    items.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> restore(String id) async {
    restored.add(id);
  }

  @override
  Future<String?> addressLine() async => address;
}

class FakeItemSummaryRepository implements ItemSummaryRepository {
  FakeItemSummaryRepository(this.items);

  final Map<ItemRef, ItemSummary> items;

  @override
  Future<ItemSummary?> get(ItemRef item) async => items[item];
}

class FakeItemPhotosRepository implements ItemPhotosRepository {
  FakeItemPhotosRepository([List<ItemPhoto> photos = const []])
    : photos = [...photos];

  final List<ItemPhoto> photos;
  Object? addError;
  Object? deleteError;
  final List<ItemPhotoType> addedTypes = [];
  final List<ItemRef> addedFor = [];
  final List<String> deleted = [];

  @override
  Future<List<ItemPhoto>> list(ItemRef item) async => [
    for (final p in photos)
      if ((item.isSystem ? p.systemId : p.applianceId) == item.id) p,
  ];

  @override
  Future<Map<String, String>> signedUrls(List<ItemPhoto> photos) async => {};

  @override
  Future<ItemPhoto> add(
    ItemRef item,
    XFile file,
    ItemPhotoType type, {
    String? caption,
  }) async {
    if (addError != null) throw addError!;
    addedTypes.add(type);
    addedFor.add(item);
    final photo = aPhoto(
      'added${addedTypes.length}',
      applianceId: item.isAppliance ? item.id : null,
      systemId: item.isSystem ? item.id : null,
      type: type.value,
    );
    photos.add(photo);
    return photo;
  }

  @override
  Future<void> delete(ItemPhoto photo) async {
    if (deleteError != null) throw deleteError!;
    deleted.add(photo.id);
    photos.removeWhere((p) => p.id == photo.id);
  }
}

class FakeItemCompletionsRepository implements ItemCompletionsRepository {
  FakeItemCompletionsRepository([this.completions = const []]);

  final List<ItemCompletion> completions;
  Object? error;

  @override
  Future<List<ItemCompletion>> list(ItemRef item) async {
    if (error != null) throw error!;
    return completions;
  }
}

class FakeItemDocumentsRepository implements ItemDocumentsRepository {
  FakeItemDocumentsRepository([this.documents = const []]);

  final List<ItemDocument> documents;

  @override
  Future<List<ItemDocument>> list(ItemRef item, {String? warrantyDocId}) async =>
      documents;
}

// ─── Wiring ───────────────────────────────────────────────────────────────────

const ItemSummary washerSummary = ItemSummary(
  item: ItemRef.appliance('wa'),
  name: 'Washer',
  brand: 'Halden',
  model: 'HW45-FL2',
);

const ItemSummary furnaceSummary = ItemSummary(
  item: ItemRef.system('fu'),
  name: 'Furnace',
  brand: 'Northline',
  model: 'NF95-080B',
);

List<Override> cOverrides({
  FakeAppliancesRepository? appliances,
  FakeItemPhotosRepository? photos,
  FakeItemCompletionsRepository? completions,
  FakeItemDocumentsRepository? documents,
  FakeItemServiceLogRepository? log,
  FakeMaintenanceTasksRepository? tasks,
  Map<ItemRef, ItemSummary>? summaries,
  bool premium = false,
}) => [
  appliancesRepositoryProvider.overrideWithValue(
    appliances ?? FakeAppliancesRepository(kitAppliances()),
  ),
  itemPhotosRepositoryProvider.overrideWithValue(
    photos ?? FakeItemPhotosRepository(),
  ),
  itemCompletionsRepositoryProvider.overrideWithValue(
    completions ?? FakeItemCompletionsRepository(),
  ),
  itemDocumentsRepositoryProvider.overrideWithValue(
    documents ?? FakeItemDocumentsRepository(),
  ),
  itemServiceLogRepositoryProvider.overrideWithValue(
    log ?? FakeItemServiceLogRepository(),
  ),
  itemSummaryRepositoryProvider.overrideWithValue(
    FakeItemSummaryRepository(
      summaries ?? {washerSummary.item: washerSummary, furnaceSummary.item: furnaceSummary},
    ),
  ),
  ...tasksOverrides(tasks ?? FakeMaintenanceTasksRepository(const [])),
  isPremiumProvider.overrideWithValue(premium),
];

/// Where a route was pushed, with its `extra`.
class Visit {
  const Visit(this.path, this.extra);

  final String path;
  final Object? extra;
}

/// Routes [home] at `/` and records every push to the routes these screens
/// reach.
class CApp extends StatelessWidget {
  CApp({
    super.key,
    required Widget home,
    required this.overrides,
    required this.visits,
  }) : _router = GoRouter(
         routes: [
           GoRoute(path: '/', builder: (_, _) => home),
           for (final path in [
             AppRoutes.home,
             AppRoutes.homeScan,
             AppRoutes.homeAppliances,
             AppRoutes.homeAppliancesAdd,
             AppRoutes.homeApplianceDetail,
             AppRoutes.homeApplianceTasks,
             AppRoutes.homeAppliancePhotos,
             AppRoutes.homeApplianceReminders,
             AppRoutes.homeSystemDetail,
             AppRoutes.homeSystemTasks,
             AppRoutes.homeSystemReminders,
             AppRoutes.maintenanceCreate,
             AppRoutes.maintenanceTaskDetail,
             AppRoutes.documentDetail,
           ])
             GoRoute(
               path: path,
               builder: (context, state) {
                 visits.add(Visit(state.uri.path, state.extra));
                 return Scaffold(body: Text('route ${state.uri.path}'));
               },
             ),
         ],
       );

  final List<Override> overrides;
  final List<Visit> visits;
  final GoRouter _router;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: _router),
  );
}

/// Pumps [screen] at `/` on a phone surface and lets it load.
Future<List<Visit>> openScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override>? overrides,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final visits = <Visit>[];
  await tester.pumpWidget(
    CApp(home: screen, overrides: overrides ?? cOverrides(), visits: visits),
  );
  await settle(tester);
  return visits;
}

/// [MaintenanceTask] linked to the washer.
MaintenanceTask washerTask(
  String id,
  String name, {
  required DateTime due,
  int? minutes,
  DiyOrPro who = DiyOrPro.diy,
  RecurrenceType recurrence = RecurrenceType.none,
}) => task(
  id,
  name,
  due: due,
  category: 'Laundry',
  minutes: minutes,
  who: who,
  recurrence: recurrence,
).copyWith(linkedApplianceId: 'wa');

/// Tasks that remember what was inserted, and show it afterwards.
class RecordingTasksRepository extends FakeMaintenanceTasksRepository {
  RecordingTasksRepository(super.tasks);

  final List<Map<String, dynamic>> inserted = [];

  @override
  Future<void> insertTask(Map<String, dynamic> fields) async {
    inserted.add(fields);
    tasks = [
      ...tasks,
      task(
        'warranty${inserted.length}',
        fields['name'] as String,
        due: DateTime.parse(fields['due_date'] as String),
      ).copyWith(
        linkedApplianceId: fields['linked_appliance_id'] as String?,
        tags: List<String>.from(fields['tags'] as List),
      ),
    ];
  }
}

/// A document for the Documents card.
ItemDocument aDoc(
  String id,
  String name, {
  String? type,
  String? mime = 'application/pdf',
  int? pages,
  DateTime? expires,
}) => ItemDocument(
  id: id,
  name: name,
  createdAt: DateTime(2026, 1, 1),
  typeName: type,
  mimeType: mime,
  pageCount: pages,
  expirationDate: expires,
);
