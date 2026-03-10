import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../services/storage_service.dart';
import '../../../services/supabase_service.dart';
import '../models/project_photo.dart';

part 'project_photos_provider.g.dart';

const _kBucket = 'project-photos';

const _kColumns =
    'id, project_id, storage_path, photo_type, room_tag, phase_id, pair_id, caption, created_at';

@riverpod
class ProjectPhotosNotifier extends _$ProjectPhotosNotifier {
  @override
  Future<List<ProjectPhoto>> build(String projectId) async {
    return _fetch();
  }

  Future<List<ProjectPhoto>> _fetch() async {
    final client = SupabaseService.client;
    final rows = await client
        .from('project_photos')
        .select(_kColumns)
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    if (rows.isEmpty) return [];

    final storage = StorageService();
    final urls = await Future.wait(
      rows.map((r) => storage.getSignedUrl(
            bucket: _kBucket,
            path: r['storage_path'] as String,
          )),
    );

    return List.generate(
      rows.length,
      (i) => ProjectPhoto.fromJson(rows[i]).copyWith(signedUrl: urls[i]),
    );
  }

  /// Picks an image (already selected via [ImagePicker]) and uploads it.
  /// Returns the new photo's ID.
  Future<String> uploadPhoto({
    required XFile file,
    required String photoType,
    String? roomTag,
    String? phaseId,
    String? caption,
  }) async {
    final client = SupabaseService.client;
    final project = await client
        .from('projects')
        .select('property_id')
        .eq('id', projectId)
        .single();
    final propertyId = project['property_id'] as String;
    final userId = client.auth.currentUser!.id;

    final ext = file.name.split('.').last.toLowerCase();
    final filename = '${const Uuid().v4()}.$ext';
    final storagePath = '$userId/$propertyId/$projectId/$filename';

    final storage = StorageService();
    await storage.uploadFile(
      bucket: _kBucket,
      path: storagePath,
      file: File(file.path),
      contentType: 'image/jpeg',
    );

    final row = await client.from('project_photos').insert({
      'project_id': projectId,
      'user_id': userId,
      'storage_path': storagePath,
      'photo_type': photoType,
      // ignore: use_null_aware_elements
      if (roomTag case final r? when r.isNotEmpty) 'room_tag': r,
      // ignore: use_null_aware_elements
      if (phaseId != null) 'phase_id': phaseId,
      // ignore: use_null_aware_elements
      if (caption != null && caption.isNotEmpty) 'caption': caption,
    }).select('id').single();

    // NOTE: After merge-train lands #52, also invalidate projectDetailProvider(projectId) here.
    ref.invalidateSelf();
    await future;

    return row['id'] as String;
  }

  /// Links a before and after photo with a shared [pairId].
  Future<void> pairPhotos(String beforeId, String afterId) async {
    final pairId = const Uuid().v4();
    await SupabaseService.client
        .from('project_photos')
        .update({'pair_id': pairId}).inFilter('id', [beforeId, afterId]);

    ref.invalidateSelf();
    await future;
  }

  /// Deletes the photo file from storage and removes the DB row.
  Future<void> deletePhoto(String photoId, String storagePath) async {
    final client = SupabaseService.client;
    final storage = StorageService();

    await storage.deleteFile(bucket: _kBucket, path: storagePath);
    await client.from('project_photos').delete().eq('id', photoId);

    ref.invalidateSelf();
    await future;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
