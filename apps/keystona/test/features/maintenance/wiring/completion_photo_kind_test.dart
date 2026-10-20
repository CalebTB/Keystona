import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/maintenance/models/completion_photo.dart';
import 'package:keystona/features/maintenance/models/task_log_draft.dart';
import 'package:keystona/features/maintenance/repositories/supabase_task_detail_repository.dart';
import 'package:keystona/features/maintenance/repositories/task_columns.dart';
import 'package:keystona/features/maintenance/repositories/task_rows.dart';

Map<String, dynamic> _row({String? kind, String? caption}) => {
  'id': 'p1',
  'completion_id': 'c1',
  'file_path': 'u/p/c1/a.jpg',
  'kind': kind,
  'caption': caption,
};

void main() {
  group('written', () {
    const base = (completionId: 'c1', userId: 'u1', path: 'u/p/c1/a.jpg');

    Map<String, dynamic> row(LogPhoto photo) => TaskRows.completionPhoto(
      completionId: base.completionId,
      userId: base.userId,
      path: base.path,
      photo: photo,
    );

    test('the slot decides the kind: first before, second after', () {
      expect(
        row(const LogPhoto(path: '/a', name: 'a', kind: PhotoKind.before)),
        containsPair('kind', 'before'),
      );
      expect(
        row(const LogPhoto(path: '/b', name: 'b', kind: PhotoKind.after)),
        containsPair('kind', 'after'),
      );
    });

    test('a later photo has no kind', () {
      expect(
        row(const LogPhoto(path: '/c', name: 'c')),
        containsPair('kind', null),
      );
    });

    test('the role never goes into caption', () {
      final r = row(
        const LogPhoto(path: '/a', name: 'a', kind: PhotoKind.before),
      );
      expect(r.containsKey('caption'), isFalse);
      expect(r.keys.toSet(), {'completion_id', 'user_id', 'file_path', 'kind'});
    });

    test('slots map to kinds', () {
      expect(PhotoKind.forSlot(0), PhotoKind.before);
      expect(PhotoKind.forSlot(1), PhotoKind.after);
      expect(PhotoKind.forSlot(2), isNull);
    });
  });

  group('read', () {
    test('kind is read from the column', () {
      expect(
        SupabaseTaskDetailRepository.photoFromRow(_row(kind: 'before')).kind,
        PhotoKind.before,
      );
      expect(
        SupabaseTaskDetailRepository.photoFromRow(_row(kind: 'after')).kind,
        PhotoKind.after,
      );
    });

    test('kind wins over a caption that says otherwise', () {
      final p = SupabaseTaskDetailRepository.photoFromRow(
        _row(kind: 'after', caption: 'before'),
      );
      expect(p.kind, PhotoKind.after);
    });

    test('a caption of before/after counts only when kind is NULL', () {
      expect(
        SupabaseTaskDetailRepository.photoFromRow(_row(caption: 'before')).kind,
        PhotoKind.before,
      );
      expect(
        SupabaseTaskDetailRepository.photoFromRow(_row(caption: 'after')).kind,
        PhotoKind.after,
      );
    });

    test('a real caption is not a role and stays a caption', () {
      final p = SupabaseTaskDetailRepository.photoFromRow(
        _row(caption: 'New filter in place'),
      );
      expect(p.kind, isNull);
      expect(p.caption, 'New filter in place');
    });

    test('a photo with neither has no role', () {
      expect(SupabaseTaskDetailRepository.photoFromRow(_row()).kind, isNull);
    });

    test('the select lists only columns that exist', () {
      final cols = TaskColumns.completionPhoto.split(', ');
      expect(cols, contains('kind'));
      expect(cols, contains('caption'));
      const existing = {
        'id',
        'completion_id',
        'user_id',
        'file_path',
        'thumbnail_path',
        'caption',
        'kind',
        'created_at',
      };
      expect(existing.containsAll(cols), isTrue);
    });
  });
}
