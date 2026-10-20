import 'document_upload_state.dart';

/// What a renewal carries over from the document being replaced: the name,
/// category, tags and what it is linked to. Notes and dates are not carried.
class RenewalSource {
  const RenewalSource({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    this.tags = const [],
    this.link,
  });

  /// The document being renewed.
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final List<String> tags;
  final UploadLink? link;
}
