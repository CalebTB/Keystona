import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:image_picker/image_picker.dart';
import 'package:keystona/features/home_profile/models/property_brief.dart';
import 'package:keystona/features/home_profile/models/system.dart';
import 'package:keystona/features/home_profile/models/system_detail.dart';
import 'package:keystona/features/home_profile/models/system_document.dart';
import 'package:keystona/features/home_profile/providers/system_repositories_provider.dart';
import 'package:keystona/features/home_profile/repositories/system_documents_repository.dart';
import 'package:keystona/features/home_profile/repositories/system_photos_repository.dart';
import 'package:keystona/features/home_profile/repositories/systems_repository.dart';
import 'package:keystona/services/providers/service_providers.dart';

/// A system as the kit's furnace, built 2021.
HomeSystem aSystem(
  String id, {
  String name = 'Furnace',
  SystemCategory category = SystemCategory.hvac,
  String? installed = '2021-03-01',
  int life = 15,
  String? brand = 'Northline',
  String? model = 'NF95-080B',
  String? location = 'Basement utility room',
  String? warrantyExpiration,
  String? linkedWarrantyDocId,
  ItemStatus status = ItemStatus.active,
  Map<String, dynamic>? specifications,
  double? purchasePrice,
  double? replacementCost,
}) => HomeSystem(
  id: id,
  propertyId: 'p1',
  userId: 'u1',
  category: category,
  systemType: 'furnace',
  name: name,
  status: status,
  brand: brand,
  modelNumber: model,
  location: location,
  installationDate: installed,
  expectedLifespanMin: life,
  expectedLifespanMax: life,
  warrantyExpiration: warrantyExpiration,
  linkedWarrantyDocId: linkedWarrantyDocId,
  specifications: specifications,
  purchasePrice: purchasePrice,
  estimatedReplacementCost: replacementCost,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

/// In-memory systems: nothing reaches Supabase.
class FakeSystemsRepository implements SystemsRepository {
  FakeSystemsRepository(
    List<HomeSystem> systems, {
    this.brief = const PropertyBrief(
      id: 'p1',
      addressLine1: '1428 Elm Hollow',
      yearBuilt: 1998,
    ),
  }) : systems = [...systems];

  final List<HomeSystem> systems;
  PropertyBrief? brief;
  Object? failList;
  Object? failWrites;
  final List<Map<String, dynamic>> created = [];
  final List<({String id, Map<String, dynamic> fields})> updates = [];
  final List<String> deleted = [];
  final List<String> restored = [];

  @override
  Future<PropertyBrief?> property() async => brief;

  @override
  Future<List<HomeSystem>> list() async {
    if (failList != null) throw failList!;
    return [...systems];
  }

  @override
  Future<HomeSystem> fetch(String id) async =>
      systems.firstWhere((s) => s.id == id);

  @override
  Future<String> create(Map<String, dynamic> fields) async {
    if (failWrites != null) throw failWrites!;
    created.add(fields);
    return 'new${created.length}';
  }

  @override
  Future<void> update(String id, Map<String, dynamic> fields) async {
    if (failWrites != null) throw failWrites!;
    updates.add((id: id, fields: fields));
  }

  @override
  Future<void> softDelete(String id) async {
    if (failWrites != null) throw failWrites!;
    deleted.add(id);
    systems.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> restore(String id) async => restored.add(id);
}

class FakeSystemPhotosRepository implements SystemPhotosRepository {
  FakeSystemPhotosRepository({this.summaryValue = SystemPhotoSummary.none});

  SystemPhotoSummary summaryValue;
  Object? failUpload;
  final List<({String systemId, String type, String name})> uploads = [];

  @override
  Future<SystemPhotoSummary> summary(String systemId) async => summaryValue;

  @override
  Future<void> upload(
    String systemId,
    XFile photo, {
    required String photoType,
  }) async {
    if (failUpload != null) throw failUpload!;
    uploads.add((systemId: systemId, type: photoType, name: photo.name));
  }
}

class FakeSystemDocumentsRepository implements SystemDocumentsRepository {
  FakeSystemDocumentsRepository([this.docs = const []]);

  final List<SystemDocument> docs;

  @override
  Future<List<SystemDocument>> forSystem(
    String systemId, {
    String? warrantyDocId,
  }) async => docs;
}

/// Everything the Systems screens read, faked. Add the task and log overrides
/// the screen needs.
List<Override> systemOverrides({
  required FakeSystemsRepository systems,
  FakeSystemPhotosRepository? photos,
  FakeSystemDocumentsRepository? documents,
  bool online = true,
  bool premium = false,
}) => [
  systemsRepositoryProvider.overrideWithValue(systems),
  systemPhotosRepositoryProvider.overrideWithValue(
    photos ?? FakeSystemPhotosRepository(),
  ),
  systemDocumentsRepositoryProvider.overrideWithValue(
    documents ?? FakeSystemDocumentsRepository(),
  ),
  isOnlineProvider.overrideWith((ref) => Stream.value(online)),
  isPremiumProvider.overrideWithValue(premium),
];
