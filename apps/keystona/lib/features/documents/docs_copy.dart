import 'package:intl/intl.dart';

import '../../core/widgets/upgrade_sheet.dart';
import '../subscription/providers/subscription_provider.dart';
import 'models/docs_expiry.dart';
import 'models/document_format.dart';

/// Copy for the Docs tab (kit: DocsSearchLed, DocsEmpty).
abstract final class DocsCopy {
  static const String title = 'Documents';
  static const String addSemantics = 'Add a document';
  static const String searchSemantics = 'Search documents';
  static const String searchHint = 'Search or pick a category';
  static const String loadError = "Couldn't load your documents.";

  // ─── Header ─────────────────────────────────────────────────────────────────

  /// "12 OF 25 · FREE PLAN" on the free plan, "12 DOCUMENTS · PREMIUM" after.
  static String eyebrow(int count, {required bool isPremium}) => isPremium
      ? '$count ${count == 1 ? 'DOCUMENT' : 'DOCUMENTS'} · PREMIUM'
      : '$count OF $kFreeDocumentLimit · FREE PLAN';

  static String expiringSubtitle(int count) => '$count expiring soon';

  // ─── Expiring soon ──────────────────────────────────────────────────────────

  static const String expiringHeader = 'EXPIRING SOON';
  static const String uploadRenewal = 'Upload renewal';
  static const String remindMe = 'Remind me';
  static const String remindUnavailable =
      "Reminders for documents aren't available yet.";

  static String allExpiring(int count) => 'All expiring dates · $count';

  /// "9 days left", "Expired", "Today" for the pill on the expiring card.
  static String daysLeft(DocsExpiry expiry) {
    if (expiry.expired) return 'Expired';
    if (expiry.isToday) return 'Today';
    return '${_days(expiry.days)} left';
  }

  /// Insurance gets the kit copy; other documents get the same sentence
  /// without the policy wording.
  static String expiringBody({
    required String? categoryName,
    required DateTime date,
  }) {
    final when = DateFormat('MMM d').format(date);
    final isInsurance = (categoryName ?? '').toLowerCase().contains(
      'insurance',
    );
    return isInsurance
        ? 'Renews $when. Upload the new declarations page so your coverage '
              'stays on record.'
        : 'Expires $when. Upload the new copy so it stays on record.';
  }

  /// "INSURANCE · ADDED MAY 12".
  static String addedMeta(String? categoryName, DateTime added) {
    final when = DateFormat('MMM d').format(added);
    return [
      if (categoryName != null && categoryName.isNotEmpty) categoryName,
      'Added $when',
    ].join(' · ').toUpperCase();
  }

  /// "1 more · Dishwasher warranty ends Nov 18".
  static String moreLine(int more, String name, DateTime date) =>
      '$more more · $name ends ${DateFormat('MMM d').format(date)}';

  // ─── Ended ──────────────────────────────────────────────────────────────────

  /// Meta line of an "Already ended" row: "ENDED JUN 2024 · KEPT FOR YOUR
  /// RECORD".
  static String endedMeta(DateTime endedOn) =>
      'ENDED ${DocumentFormat.monthYearUpper(endedOn)} · KEPT FOR YOUR RECORD';

  // ─── Renewal ────────────────────────────────────────────────────────────────

  static String renewing(String name) => 'Renewing $name';
  static const String renewalReplacesFile =
      'Saving replaces the old file with the new one.';
  static const String renewalDateHelp = 'Pick the new end date';
  static const String renewalSaved = 'Document renewed';
  static const String renewalLoadError =
      "We couldn't load the document you're renewing. "
      'Check your connection and try again.';

  // ─── Recently added ─────────────────────────────────────────────────────────

  static const String recentHeader = 'RECENTLY ADDED';
  static String seeAll(int count) => 'See all $count';

  /// "MAINTENANCE · OCT 2".
  static String rowMeta(String? categoryName, DateTime added) {
    final when = DateFormat('MMM d').format(added);
    return [
      if (categoryName != null && categoryName.isNotEmpty) categoryName,
      when,
    ].join(' · ').toUpperCase();
  }

  /// Pill on a document row: "9 DAYS", "TO 2035", "EXPIRED".
  static String rowPill(DocsExpiry expiry, {bool long = false}) {
    if (expiry.expired) return 'EXPIRED';
    if (expiry.isToday) return 'TODAY';
    if (expiry.tone == DocsExpiryTone.far) {
      return long ? 'EXPIRES ${expiry.date.year}' : 'TO ${expiry.date.year}';
    }
    return long ? 'EXPIRES IN ${_days(expiry.days)}' : _days(expiry.days);
  }

  static String _days(int n) => n == 1 ? '1 DAY' : '$n DAYS';

  // ─── Empty-category hint ────────────────────────────────────────────────────

  /// What belongs in a standard category that has nothing yet. Categories
  /// without an entry here get no hint.
  static const Map<String, String> categoryHints = {
    'tax & financial': 'Mortgage papers, tax bills, improvement receipts',
  };

  /// Display name used in "Nothing in Financial yet".
  static const Map<String, String> categoryShortNames = {
    'tax & financial': 'Financial',
  };

  static String? hintFor(String categoryName) =>
      categoryHints[categoryName.toLowerCase()];

  static String nothingIn(String categoryName) =>
      'Nothing in ${categoryShortNames[categoryName.toLowerCase()] ?? categoryName} yet';

  // ─── Empty vault ────────────────────────────────────────────────────────────

  static const String emptyTitle = 'Your vault is ready';
  static const String emptyBody =
      'Keep the papers that protect your home in one place, and get a '
      'heads-up before anything expires.';
  static const String addDocument = 'Add a document';
  static const String scanWithCamera = 'Scan with camera';
  static const String startWith = 'START WITH THESE';
  static const String emptyFootnote =
      'Each one raises the Documents part of your home health score.';

  static const List<({String title, String meta})> suggestions = [
    (
      title: 'Homeowners insurance policy',
      meta: 'INSURANCE · TRACKS YOUR RENEWAL',
    ),
    (title: 'Closing disclosure', meta: 'OWNERSHIP · NEEDED FOR TAXES'),
    (
      title: 'An appliance warranty',
      meta: 'WARRANTIES · ALERTS BEFORE IT ENDS',
    ),
  ];

  // ─── Delete ─────────────────────────────────────────────────────────────────

  /// Subtitle of the Undo snackbar after a delete; matches
  /// `AuroraDurations.undoDelete`.
  static const String deleteUndoHint = 'Undo within 10 seconds.';

  // ─── Free-plan limit ────────────────────────────────────────────────────────

  static const UpgradeSheetConfig limitSheet = UpgradeSheetConfig(
    headline: 'Unlock Unlimited Documents',
    reason:
        'Your Document Vault is full with $kFreeDocumentLimit documents on '
        'the Free plan.',
    features: [
      'Unlimited document storage',
      'Full-text search across all docs',
      'Home health score tracking',
      'Weather-based maintenance alerts',
    ],
    triggerKey: 'doc_limit',
  );
}
