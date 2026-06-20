// ignore_for_file: invalid_annotation_target
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/theme/app_colors.dart';

part 'project_photo.freezed.dart';
part 'project_photo.g.dart';

/// A photo stored in the `project-photos` bucket and tracked in `project_photos`.
@freezed
abstract class ProjectPhoto with _$ProjectPhoto {
  const factory ProjectPhoto({
    required String id,
    required String projectId,
    required String storagePath,
    /// Signed URL — computed at load time, not persisted.
    String? signedUrl,
    required String photoType,
    String? roomTag,
    String? phaseId,
    /// UUID linking a before photo to its after partner.
    String? pairId,
    String? caption,
    required DateTime createdAt,
  }) = _ProjectPhoto;

  factory ProjectPhoto.fromJson(Map<String, dynamic> json) =>
      _$ProjectPhotoFromJson(json);
}

/// Photo type values, labels, and badge colors.
abstract final class PhotoTypes {
  static const all = [
    (value: 'before', label: 'Before'),
    (value: 'after', label: 'After'),
    (value: 'progress', label: 'Progress'),
    (value: 'inspiration', label: 'Inspiration'),
    (value: 'issue', label: 'Issue'),
  ];

  static String labelFor(String value) => all
      .firstWhere((t) => t.value == value,
          orElse: () => (value: value, label: value))
      .label;

  static ({Color background, Color foreground}) colorFor(String value) =>
      switch (value) {
        'before' => (
            background: AppColors.photoBadgeBeforeBg,
            foreground: AppColors.photoBadgeBeforeFg,
          ),
        'after' => (
            background: AppColors.photoBadgeAfterBg,
            foreground: AppColors.photoBadgeAfterFg,
          ),
        'progress' => (
            background: AppColors.photoBadgeProgressBg,
            foreground: AppColors.goldAccent,
          ),
        'inspiration' => (
            background: AppColors.photoBadgeInspirationBg,
            foreground: AppColors.photoBadgeInspirationFg,
          ),
        'issue' => (
            background: AppColors.errorLight,
            foreground: AppColors.error,
          ),
        _ => (
            background: AppColors.photoBadgeOtherBg,
            foreground: AppColors.photoBadgeOtherFg,
          ),
      };
}
