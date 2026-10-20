import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/system_detail.dart';
import '../models/system_document.dart';
import 'home_profile_provider.dart';
import 'system_repositories_provider.dart';
import 'systems_provider.dart';

part 'system_detail_provider.g.dart';

/// One system with what its photos say. Keyed by id and auto-disposed when
/// the detail screen closes.
@riverpod
class SystemDetailNotifier extends _$SystemDetailNotifier {
  @override
  Future<SystemDetail> build(String systemId) async {
    final system = ref.read(systemsRepositoryProvider).fetch(systemId);
    // Photos are a nicety: a failure here must not blank the screen.
    final photos = ref
        .read(systemPhotosRepositoryProvider)
        .summary(systemId)
        .catchError((_) => SystemPhotoSummary.none);
    return SystemDetail(system: await system, photos: await photos);
  }

  /// Updates columns of the system, then refreshes this screen and the list.
  Future<void> updateSystem(Map<String, dynamic> fields) async {
    await ref.read(systemsRepositoryProvider).update(systemId, fields);
    ref
      ..invalidate(systemsProvider)
      ..invalidate(homeProfileProvider)
      ..invalidateSelf();
    await future;
  }
}

/// Documents linked to a system, plus its warranty document.
@riverpod
Future<List<SystemDocument>> systemDocuments(Ref ref, String systemId) async {
  final detail = await ref.watch(systemDetailProvider(systemId).future);
  return ref
      .read(systemDocumentsRepositoryProvider)
      .forSystem(systemId, warrantyDocId: detail.system.linkedWarrantyDocId);
}
