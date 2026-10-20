/// What the reader finds in a scanned document, stage by stage.
///
/// Shown on the "reading your document" card and used to pre-fill the new
/// document form. Plain value classes: never persisted.
enum OcrStage {
  readingText('Reading the text'),
  classifying('Working out what it is'),
  findingDates('Finding the dates'),
  matching('Matching it to your home');

  const OcrStage(this.label);

  /// Step title on the reading card.
  final String label;
}

/// The system or appliance a document was matched to.
class OcrLink {
  const OcrLink({
    required this.id,
    required this.isAppliance,
    required this.name,
    required this.summary,
    this.matchedOn,
  });

  final String id;

  /// True for an appliance, false for a home system.
  final bool isAppliance;

  /// "Furnace".
  final String name;

  /// One line for the matching step: "Your furnace — serial 2103A47719".
  final String summary;

  /// What the match was made on: "model NF95-080B".
  final String? matchedOn;
}

/// Everything the reader found so far. Any field may still be null.
class OcrResult {
  const OcrResult({
    this.textSummary,
    this.name,
    this.categoryName,
    this.expirationDate,
    this.expirationPage,
    this.link,
  });

  /// One line for the first step: "Northline · Limited Warranty Certificate".
  final String? textSummary;

  /// Suggested document name.
  final String? name;

  /// Suggested category, matched to a real category by name.
  final String? categoryName;

  final DateTime? expirationDate;

  /// 1-based page the date was found on.
  final int? expirationPage;

  final OcrLink? link;

  /// How many form details the reader filled in.
  int get detailCount =>
      (name != null ? 1 : 0) +
      (categoryName != null ? 1 : 0) +
      (expirationDate != null ? 1 : 0) +
      (link != null ? 1 : 0);
}

/// One update from the reader: [completed] stages are done and [result] holds
/// what they found.
class OcrProgress {
  const OcrProgress({required this.completed, required this.result});

  /// Number of stages finished, 0 to [OcrStage.values.length].
  final int completed;
  final OcrResult result;

  bool get isFinished => completed >= OcrStage.values.length;
}
