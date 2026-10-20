/// A photo attached to a task completion (`completion_photos`), with a signed
/// URL for the private `completion-photos` bucket.
class CompletionPhoto {
  const CompletionPhoto({
    required this.id,
    required this.completionId,
    required this.path,
    this.url,
    this.caption,
  });

  final String id;
  final String completionId;
  final String path;

  /// Signed URL, or null when it could not be created.
  final String? url;

  /// 'before' or 'after' on the first two photos of a log, otherwise null.
  final String? caption;
}
