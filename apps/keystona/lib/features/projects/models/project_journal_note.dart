// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_journal_note.freezed.dart';
part 'project_journal_note.g.dart';

/// A plain-text journal/note attached to a project.
@freezed
abstract class ProjectJournalNote with _$ProjectJournalNote {
  const factory ProjectJournalNote({
    required String id,
    required String projectId,
    String? phaseId,
    required String userId,
    String? title,
    required String content,
    required DateTime noteDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _ProjectJournalNote;

  factory ProjectJournalNote.fromJson(Map<String, dynamic> json) =>
      _$ProjectJournalNoteFromJson(json);
}
