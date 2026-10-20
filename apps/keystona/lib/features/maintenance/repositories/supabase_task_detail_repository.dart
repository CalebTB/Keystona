import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/completion_photo.dart';
import '../models/maintenance_task.dart';
import '../models/task_completion.dart';
import '../models/task_detail.dart';
import '../models/task_log_draft.dart';
import '../models/task_parent.dart';
import '../models/task_skip.dart';
import '../services/task_dates.dart';
import 'task_columns.dart';
import 'task_detail_repository.dart';
import 'task_rows.dart';

/// [TaskDetailRepository] over the Supabase client.
class SupabaseTaskDetailRepository implements TaskDetailRepository {
  SupabaseTaskDetailRepository(this._client);

  final SupabaseClient _client;

  static const String _photoBucket = 'completion-photos';

  /// Signed URL lifetime for completion photos, in seconds.
  static const int signedUrlSeconds = 3600;

  static const String _detailColumns =
      '${TaskColumns.task}, '
      '''
    system:systems(id, name, model, location, installation_date,
      expected_lifespan_min, expected_lifespan_max, lifespan_override),
    appliance:appliances(id, name, model, location, purchase_date,
      expected_lifespan_min, expected_lifespan_max, lifespan_override),
    completions:task_completions(${TaskColumns.completion}),
    skips:task_skips(${TaskColumns.skip}),
    template:maintenance_task_templates(instructions, tools_needed, supplies_needed)
  ''';

  @override
  Future<TaskDetail> fetchDetail(String taskId) async {
    final row = await _client
        .from('maintenance_tasks')
        .select(_detailColumns)
        .eq('id', taskId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (row == null) throw StateError('Task not found');
    return parseDetail(row, now: DateTime.now());
  }

  /// Turns a nested-select row into a [TaskDetail]. Public for tests.
  static TaskDetail parseDetail(
    Map<String, dynamic> row, {
    required DateTime now,
  }) {
    final system = row['system'] as Map<String, dynamic>?;
    final appliance = row['appliance'] as Map<String, dynamic>?;
    final completionRows = (row['completions'] as List<dynamic>?) ?? const [];
    final skipRows = (row['skips'] as List<dynamic>?) ?? const [];
    final template = row['template'] as Map<String, dynamic>?;

    final cleaned = Map<String, dynamic>.from(row)
      ..remove('system')
      ..remove('appliance')
      ..remove('completions')
      ..remove('skips')
      ..remove('template');

    var task = MaintenanceTask.fromJson(cleaned).copyWith(
      linkedSystemName: system?['name'] as String?,
      linkedApplianceName: appliance?['name'] as String?,
    );
    task = _fillFromTemplate(task, template);

    final completions = [
      for (final c in completionRows)
        TaskCompletion.fromJson(Map<String, dynamic>.from(c as Map)),
    ]..sort((a, b) => b.completedDate.compareTo(a.completedDate));

    final skips = [
      for (final r in skipRows)
        TaskSkip.fromRow(Map<String, dynamic>.from(r as Map)),
    ]..sort((a, b) => b.skippedOn.compareTo(a.skippedOn));

    return TaskDetail(
      task: task,
      completions: completions,
      skips: skips,
      parent: _parentOf(task, system, appliance, now),
    );
  }

  static MaintenanceTask _fillFromTemplate(
    MaintenanceTask task,
    Map<String, dynamic>? template,
  ) {
    if (template == null) return task;
    List<String> strings(Object? v) =>
        v is List ? v.whereType<String>().toList() : const [];
    return task.copyWith(
      instructions: (task.instructions == null || task.instructions!.isEmpty)
          ? template['instructions'] as String?
          : task.instructions,
      toolsNeeded: task.toolsNeeded.isEmpty
          ? strings(template['tools_needed'])
          : task.toolsNeeded,
      suppliesNeeded: task.suppliesNeeded.isEmpty
          ? strings(template['supplies_needed'])
          : task.suppliesNeeded,
    );
  }

  static TaskParent? _parentOf(
    MaintenanceTask task,
    Map<String, dynamic>? system,
    Map<String, dynamic>? appliance,
    DateTime now,
  ) {
    DateTime? date(Object? v) => v is String ? DateTime.tryParse(v) : null;
    int? whole(Object? v) => (v as num?)?.toInt();
    TaskParent item(
      TaskParentKind kind,
      Map<String, dynamic> m,
      Object? since,
    ) => TaskParent(
      kind: kind,
      id: m['id'] as String?,
      name: m['name'] as String? ?? task.category,
      model: m['model'] as String?,
      location: m['location'] as String?,
      health: TaskParent.healthOf(
        installed: date(since),
        lifespanMin: whole(m['expected_lifespan_min']),
        lifespanMax: whole(m['expected_lifespan_max']),
        lifespanOverride: whole(m['lifespan_override']),
        now: now,
      ),
    );
    if (system != null) {
      return item(TaskParentKind.system, system, system['installation_date']);
    }
    if (appliance != null) {
      return item(
        TaskParentKind.appliance,
        appliance,
        appliance['purchase_date'],
      );
    }
    return TaskParent(kind: TaskParentKind.area, name: task.category);
  }

  @override
  Future<Map<String, List<CompletionPhoto>>> completionPhotos(
    List<String> completionIds,
  ) async {
    if (completionIds.isEmpty) return const {};
    final rows = await _client
        .from('completion_photos')
        .select(TaskColumns.completionPhoto)
        .inFilter('completion_id', completionIds)
        .order('created_at');
    final photos = await Future.wait([
      for (final r in rows) _photoOf(Map<String, dynamic>.from(r)),
    ]);
    final byCompletion = <String, List<CompletionPhoto>>{};
    for (final p in photos) {
      byCompletion.putIfAbsent(p.completionId, () => []).add(p);
    }
    return byCompletion;
  }

  Future<CompletionPhoto> _photoOf(Map<String, dynamic> r) async {
    final path = r['file_path'] as String;
    String? url;
    try {
      url = await _client.storage
          .from(_photoBucket)
          .createSignedUrl(path, signedUrlSeconds);
    } catch (_) {
      url = null;
    }
    return photoFromRow(r, url: url);
  }

  /// A [CompletionPhoto] from a `completion_photos` row. Its role is the
  /// `kind` column; a caption of 'before' or 'after' counts only on a row
  /// whose kind is NULL. Public for tests.
  static CompletionPhoto photoFromRow(Map<String, dynamic> r, {String? url}) =>
      CompletionPhoto(
        id: r['id'] as String,
        completionId: r['completion_id'] as String,
        path: r['file_path'] as String,
        url: url,
        kind: PhotoKind.resolve(
          kind: r['kind'] as String?,
          caption: r['caption'] as String?,
        ),
        caption: r['caption'] as String?,
      );

  @override
  Future<String> insertCompletion({
    required MaintenanceTask task,
    required TaskLogDraft draft,
    DateTime? dueDate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');

    final row = await _client
        .from('task_completions')
        .insert(
          TaskRows.logCompletion(
            task: task,
            draft: draft,
            userId: user.id,
            dueDate: dueDate,
          ),
        )
        .select('id')
        .single();
    final completionId = row['id'] as String;

    if (draft.photos.isNotEmpty) {
      await _uploadPhotos(
        userId: user.id,
        propertyId: task.propertyId,
        completionId: completionId,
        photos: draft.photos,
      );
    }
    return completionId;
  }

  Future<void> _uploadPhotos({
    required String userId,
    required String propertyId,
    required String completionId,
    required List<LogPhoto> photos,
  }) async {
    final rows = <Map<String, dynamic>>[];
    for (final photo in photos) {
      final bytes = await File(photo.path).readAsBytes();
      final ext = photo.name.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${photo.name}';
      final path = '$userId/$propertyId/$completionId/$fileName';
      await _client.storage
          .from(_photoBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: _mimeType(ext)),
          );
      rows.add(
        TaskRows.completionPhoto(
          completionId: completionId,
          userId: userId,
          path: path,
          photo: photo,
        ),
      );
    }
    await _client.from('completion_photos').insert(rows);
  }

  static String _mimeType(String ext) => switch (ext) {
    'png' => 'image/png',
    'heic' => 'image/heic',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };

  @override
  Future<void> updateSchedule(
    String taskId, {
    required TaskStatus status,
    required DateTime dueDate,
  }) => _client
      .from('maintenance_tasks')
      .update({'status': status.value, 'due_date': TaskDates.dateStr(dueDate)})
      .eq('id', taskId);

  @override
  Future<void> deleteCompletion(String completionId) =>
      _client.from('task_completions').delete().eq('id', completionId);

  @override
  Future<void> deleteTask(String taskId) =>
      _client.rpc(TaskRpc.softDelete, params: TaskRpc.args(taskId));

  @override
  Future<void> restoreTask(String taskId) =>
      _client.rpc(TaskRpc.restore, params: TaskRpc.args(taskId));
}
