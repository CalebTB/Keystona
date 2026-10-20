/// The part a completion photo plays: the picture before the work or the one
/// after (`completion_photos.kind`, NULL or one of these).
enum PhotoKind {
  before('before'),
  after('after');

  const PhotoKind(this.value);

  /// The stored value.
  final String value;

  /// The kind stored as [value], or null when it is none of them.
  static PhotoKind? parse(String? value) {
    for (final k in values) {
      if (k.value == value) return k;
    }
    return null;
  }

  /// The role of the photo in slot [index] of a log: the first is the
  /// before, the second the after, the rest have none.
  static PhotoKind? forSlot(int index) => switch (index) {
    0 => PhotoKind.before,
    1 => PhotoKind.after,
    _ => null,
  };

  /// What a stored row says: its `kind`, or, only for a row whose kind is
  /// NULL (saved before the column existed), a caption that reads exactly
  /// 'before' or 'after'.
  static PhotoKind? resolve({String? kind, String? caption}) =>
      kind != null ? parse(kind) : parse(caption);
}

/// A photo attached to a task completion (`completion_photos`), with a signed
/// URL for the private `completion-photos` bucket.
class CompletionPhoto {
  const CompletionPhoto({
    required this.id,
    required this.completionId,
    required this.path,
    this.url,
    this.kind,
    this.caption,
  });

  final String id;
  final String completionId;
  final String path;

  /// Signed URL, or null when it could not be created.
  final String? url;

  /// Before or after the work; null for any other photo.
  final PhotoKind? kind;

  /// A real caption. Never the before/after role, which is [kind].
  final String? caption;
}
