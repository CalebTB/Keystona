import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_category.freezed.dart';
part 'document_category.g.dart';

/// A category used to organize documents in the Document Vault.
///
/// System categories (isSystem = true) are provided by Keystona and cannot
/// be deleted. User-created categories have a non-null [userId].
@freezed
abstract class DocumentCategory with _$DocumentCategory {
  const factory DocumentCategory({
    required String id,
    String? userId,
    required String name,
    required String icon,

    /// Hex color string, e.g. '#1565C0'. Parsed when rendering category badge.
    required String color,
    required bool isSystem,
    required int sortOrder,
    required DateTime createdAt,
  }) = _DocumentCategory;

  factory DocumentCategory.fromJson(Map<String, dynamic> json) =>
      _$DocumentCategoryFromJson(json);
}
