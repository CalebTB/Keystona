/// How a renewal is opened.
///
/// A renewal updates an existing document in place: the new file and the new
/// end date go onto the same row. The add-document route is opened with the
/// id of that document in [queryParam].
abstract final class DocumentRenewal {
  /// Query parameter on the add-document route: `?renew=<documentId>`.
  static const String queryParam = 'renew';

  /// The add-document location, in renewal mode for [documentId].
  static String location(String uploadPath, String documentId) => Uri(
    path: uploadPath,
    queryParameters: {queryParam: documentId},
  ).toString();
}
