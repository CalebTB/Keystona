import 'document_upload_state.dart';

/// What a renewal carries over from the document being renewed: the name,
/// category, tags, notes and what it is linked to. The end date is not
/// carried: a renewal asks for the new one.
class RenewalSource {
  const RenewalSource({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    this.notes = '',
    this.tags = const [],
    this.link,
  });

  /// The document being renewed.
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final String notes;
  final List<String> tags;
  final UploadLink? link;
}
