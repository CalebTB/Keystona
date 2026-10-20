import 'package:intl/intl.dart';

import '../../core/theme/aurora_home_b.dart';
import 'lifespan/lifespan_reading.dart';
import 'models/system.dart';

/// Every string on the Systems screens: list, scan, add / edit, detail and
/// the "Log a repair or service" sheet. Copy the kit draws is verbatim; copy
/// marked "invented" had no kit text and needs review.
abstract final class SystemsCopy {
  // ── List ──────────────────────────────────────────────────────────────────
  static const String listTitle = 'Systems';
  static const String homeBack = 'Home profile';
  static const String add = '+ Add';
  static const String addSemantics = 'Add a system';
  static const String sortOldest = 'Oldest first';
  static const String sortAz = 'A–Z';
  static String filterAll(int n) => 'All $n';
  static const String scanToAdd = 'Scan a label to add one';
  static const String suggestionsCaption =
      'TRACKING THEM ADDS THEIR UPKEEP REMINDERS';
  static String suggestionsTitle(int? yearBuilt) => yearBuilt == null
      ? 'OFTEN FORGOTTEN, NOT TRACKED YET'
      : 'COMMON IN A $yearBuilt HOME, NOT TRACKED YET';

  /// Eyebrow: "1428 ELM HOLLOW · 5 TRACKED · 1 AGING".
  static String listEyebrow({
    String? address,
    required int tracked,
    required int aging,
  }) => [
    if (address != null && address.trim().isNotEmpty) address.toUpperCase(),
    '$tracked TRACKED',
    if (aging > 0) '$aging AGING',
  ].join(' · ');

  static String warrantyNote(DateTime ends) =>
      'Warranty ends ${DateFormat.MMMd().format(ends)}';

  // Empty state (Empty States Catalog, "Systems list (no systems)").
  static const String emptyTitle = "Add your home's systems";
  static const String emptySubtitle =
      'Systems are the major components of your home — HVAC, plumbing, '
      'electrical, roofing, and more. Adding them unlocks personalized '
      'maintenance tasks and lifespan tracking.';
  static const String emptyAction = '+ Add First System';

  /// Invented: second action on the empty state.
  static const String emptyScan = 'Scan a label';

  /// Invented.
  static const String loadError = "Couldn't load your systems.";

  // ── Scan ──────────────────────────────────────────────────────────────────
  static const String scanEyebrow = 'SMART SCAN';
  static const String scanChooseTitle = 'What are you scanning?';
  static const String scanChooseBody =
      "Point at the label with the brand, model and serial number. We'll fill "
      'in the rest.';
  static const String scanSystemTitle = 'A system';
  static const String scanSystemBody =
      'HVAC, water heater, electrical panel, roof, plumbing';
  static const String scanApplianceTitle = 'An appliance';
  static const String scanApplianceBody =
      'Fridge, washer, dryer, dishwasher, oven';
  static String scanInYourHome(int n) => '$n IN YOUR HOME';
  static const String scanByHand = 'No label? Add it by hand';
  static const String scanClose = 'Close';
  static const String scanBack = 'Back';
  static const String scanSystemCamera = 'Scan a system label';
  static const String scanApplianceCamera = 'Scan an appliance label';
  static const String scanSegmentSystem = 'System';
  static const String scanSegmentAppliance = 'Appliance';
  static const String scanHintSystem = 'Fit the rating plate inside the frame';
  static const String scanHintAppliance =
      'Fit the model & serial sticker inside the frame';
  static const String scanShutter = 'Take a photo of the label';
  static const String scanTypeItIn = 'Type it in instead';
  static const String scanReview = 'Review details →';

  /// Invented: the picture is being read.
  static const String scanReading = 'Reading the label…';
  static String scanFound(int n) =>
      'Label read · $n ${n == 1 ? 'detail' : 'details'} found';

  /// Invented: the read found nothing, or failed.
  static const String scanNothing =
      "Couldn't read any info from that label. Try a clearer photo.";
  static const String scanFailed =
      'Something went wrong. Check your connection and try again.';

  /// Invented: offline (Implementation Notes: Scan dims offline, with a
  /// snackbar).
  static const String scanOffline =
      "You're offline. Scanning needs a connection; you can type it in.";

  // ── Add / edit ────────────────────────────────────────────────────────────
  static const String formBackScan = 'Scan';
  static const String eyebrowNew = 'HOME PROFILE · NEW';
  static const String eyebrowEdit = 'HOME PROFILE · EDIT';
  static const String titleNew = 'Add a system.';
  static String titleEdit(String name) => 'Edit $name.';
  static String bannerTitle(int n) =>
      'We read $n ${n == 1 ? 'field' : 'fields'} from the label';
  static const String bannerBodyStart = 'The ones edged in ';
  static const String bannerBlue = 'blue';
  static const String bannerBodyEnd = ' came from it — check them, then save.';
  static const String rescan = 'Rescan';
  static const String category = 'Category';
  static const String categorySheet = 'Category';
  static const String nameLabel = 'Name';
  static const String nameHint = 'Main floor HVAC';
  static const String nameHelper = 'YOUR NAME FOR IT — E.G. "MAIN FLOOR HVAC"';

  /// Invented.
  static const String nameRequired = 'Give it a name';
  static const String sectionIdentification = 'Identification';
  static const String brand = 'Brand';
  static const String model = 'Model';
  static const String serial = 'Serial number';
  static const String serialHelper = 'FIND ON UNIT LABEL';
  static const String serialScan = 'Scan again';
  static const String sectionInstall = 'Install & lifespan';
  static const String installed = 'Installed';
  static const String month = 'Month';
  static const String year = 'Year';
  static const String monthSheet = 'Month';
  static const String yearSheet = 'Year';
  static const String expectedLifespan = 'Expected lifespan';
  static String lifeYears(int n) => '$n ${n == 1 ? 'year' : 'years'}';
  static String lifeHelp(SystemCategory c, int? replaceYear) => replaceYear ==
          null
      ? 'TYPICAL FOR ${c.label.toUpperCase()} — ADD THE INSTALL YEAR TO SEE WHEN'
      : 'TYPICAL FOR ${c.label.toUpperCase()} · PLAN TO REPLACE AROUND '
            '$replaceYear';
  static const String lifeSemantics = 'Expected lifespan in years';
  static const String addTasks = 'Add its maintenance tasks';
  static const String addTasksOff = 'OFF · YOU CAN ADD TASKS YOURSELF';

  /// Invented: the switch cannot turn on offline.
  static const String addTasksOffline =
      "You're offline. Tasks can be added once you're back online.";
  static const String sectionPhotos = 'Photos';
  static const String addPhoto = 'Add a photo';
  static const String labelTag = 'LABEL';
  static const String photosCaptionFree =
      'FREE PLAN · 4 PHOTOS · THE LABEL PHOTO IS SAVED FOR YOU';
  static const String photosCaptionPremium =
      'THE LABEL PHOTO IS SAVED FOR YOU';
  static const String photoTake = 'Take a photo';
  static const String photoChoose = 'Choose from your photos';
  static const String photoSheet = 'Add a photo';
  static const String photoRemove = 'Remove photo';

  /// Invented: the free photo limit upsell.
  static const String photoLimitHeadline = 'Keep every photo with Premium';
  static const String photoLimitReason =
      'The Free plan keeps 4 photos for each system.';
  static const List<String> photoLimitFeatures = [
    'Unlimited photos on every system and appliance',
    'Unlimited documents',
    'Search inside your documents',
  ];
  static const String photoLimitKey = 'item_photos';
  static const String cancel = 'Cancel';
  static const String saveNew = 'Save system';
  static const String saveEdit = 'Save changes';
  static const String requiredNote = 'EVERYTHING ELSE CAN WAIT';
  static const String requiredPrefix = 'REQUIRED ';
  static const String added = 'System added.';
  static const String updated = 'System updated.';
  static const String saveFailed = "Couldn't save the system. Try again.";

  /// Invented: the system saved but a photo did not.
  static const String photoFailed =
      'The system was saved, but a photo could not be uploaded.';

  // Edit mode: "More details" (invented section and labels).
  static const String sectionMore = 'More details';
  static const String location = 'Location';
  static const String locationHint = 'Basement utility room';
  static const String installer = 'Installed by';
  static const String price = 'Purchase price';
  static const String status = 'Status';
  static const String statusSheet = 'Status';
  static const String fuel = 'Fuel';
  static const String output = 'Output';
  static const String filter = 'Filter size';
  static const String warrantyProvider = 'Warranty provider';
  static const String warrantyExpires = 'Warranty expires';
  static const String warrantyPick = 'Pick a date';
  static const String warrantyClear = 'No warranty date';
  static const String warrantyDoc = 'Warranty document';
  static const String warrantyDocNone = 'None linked';
  static const String notes = 'Notes';
  static const String priceInvalid = 'Enter a price like 4850';
  static const String delete = 'Delete this system';
  static String deleteTitle(String name) => 'Delete $name?';
  static const String deleteBody =
      'It leaves your home profile. You can undo for a few seconds.';
  static const String deleteConfirm = 'Delete';
  static const String deleted = 'System deleted.';
  static const String deleteFailed = "Couldn't delete the system. Try again.";
  static const String restoreFailed = "Couldn't bring the system back.";

  // Document picker (invented).
  static const String docPickerTitle = 'Link a document';
  static const String docPickerNone = 'No document';
  static const String docPickerEmpty = 'No documents yet. Add one in Docs.';

  // ── Detail ────────────────────────────────────────────────────────────────
  static const String edit = 'Edit';
  static const String systemsBack = 'Systems';
  static String detailEyebrow(SystemCategory c) =>
      '${c.label.toUpperCase()} · SYSTEM';
  static const String chipHealthy = 'Healthy';
  static const String chipAging = 'Aging';
  static const String chipEndOfLife = 'At end of life';
  static const String chipPast = 'Past expected life';
  static const String chipNeedsRepair = 'Needs repair';
  static const String chipReplaced = 'Replaced';
  static const String chipRemoved = 'Removed';
  static const String photoTagUnit = 'UNIT';
  static const String photoTagLabel = 'LABEL';
  static String photosBadge(int n) => '$n ${n == 1 ? 'PHOTO' : 'PHOTOS'}';
  static const String lifespanSection = 'Lifespan';
  static String installedOn(DateTime d) =>
      'Installed ${DateFormat.yMMM().format(d)}';

  /// Invented: body of the lifespan card.
  static const String lifespanNoDate =
      'Add the install date to see how much life is left.';

  /// The sentence under the lifespan bar, in three parts so the years left
  /// can be bold: "About ", "9½ years left", ". Replacing it ...".
  static ({String before, String bold, String after}) lifespanBody({
    required LifespanReading reading,
    required double? cost,
    required int now,
  }) {
    final left = reading.yearsLeft;
    if (left == null) return (before: lifespanNoDate, bold: '', after: '');
    final price = cost == null
        ? null
        : 'Replacing it typically runs about ${money(cost)}';
    if (left <= 0) {
      return (
        before: 'This is past its expected life.',
        bold: '',
        after: price == null ? '' : ' $price.',
      );
    }
    final replace = reading.replaceYear;
    final planFrom = replace == null ? null : replace - planAheadYears;
    final plan = planFrom == null
        ? null
        : planFrom <= now
        ? 'time to start planning'
        : "we'll start planning with you around $planFrom";
    final after = switch ((price, plan)) {
      (final p?, final q?) => '. $p — $q.',
      (final p?, null) => '. $p.',
      (null, final q?) => '. ${q[0].toUpperCase()}${q.substring(1)}.',
      _ => '.',
    };
    return (before: 'About ', bold: '${_halfYears(left)} left', after: after);
  }

  static String _halfYears(double years) {
    final halves = (years * 2).round();
    final whole = halves ~/ 2;
    final half = halves.isOdd ? '½' : '';
    final unit = halves == 2 ? 'year' : 'years';
    return '$whole$half $unit';
  }

  /// Years before replacement the planning sentence starts.
  static const int planAheadYears = AuroraHomeBSizes.planAheadYears;

  static const String nextUpSection = 'Next up';
  static String allTasks(int n, SystemCategory c) =>
      'All $n ${c.label} ${n == 1 ? 'task' : 'tasks'}';
  static const String done = 'DONE';
  static const String proTag = 'PRO';
  static const String warrantySection = 'Warranty';
  static const String warrantyActive = 'ACTIVE';
  static const String warrantyEnded = 'ENDED';
  static const String warrantyDefaultTitle = 'Warranty';
  static String warrantyMeta(String? provider, DateTime ends, bool active) {
    final date = DateFormat.yMMM().format(ends).toUpperCase();
    final until = active ? 'UNTIL $date' : 'ENDED $date';
    return [
      if (provider != null && provider.trim().isNotEmpty)
        provider.toUpperCase(),
      until,
    ].join(' · ');
  }

  // Warranty check callout (invented, mirrors the appliance callout).
  static String warrantyCheckTitle(int days) => days <= 0
      ? 'WARRANTY ENDS TODAY'
      : 'WARRANTY ENDS IN $days ${days == 1 ? 'DAY' : 'DAYS'}';
  static String warrantyCheckBody(DateTime ends) =>
      'Covered until ${DateFormat.MMMd().format(ends)}. Anything off? Get it '
      'looked at while repairs are still free.';
  static String warrantyCheckAdd(DateTime ends) =>
      'Add a check before ${DateFormat.MMMd().format(ends)}';
  static String warrantyCheckAdded(DateTime due) =>
      '✓ Added to Tasks · ${DateFormat.MMMd().format(due)}';
  static String warrantyCheckTask(String name) =>
      'Check the $name before the warranty ends';
  static const String warrantyCheckFailed =
      "Couldn't change that task. Try again.";

  static const String identificationSection = 'Identification';
  static const String specBrand = 'BRAND';
  static const String specModel = 'MODEL';
  static const String specSerial = 'SERIAL';
  static const String specFuel = 'FUEL';
  static const String specOutput = 'OUTPUT';
  static const String specFilter = 'FILTER';
  static String historySection(int n) => 'History · $n';
  static String historyTotal(double total, int sinceYear) =>
      '${money(total)} since $sinceYear';
  static const String historyInstalled = 'Installed';
  static const String logService = '+ Log a repair or service';
  static const String historyEmptyTitle = 'No service history yet';
  static const String historyEmptyBody =
      'Completed maintenance tasks for this system will appear here with '
      'cost and notes.';
  static const String receiptSaved = 'receipt saved';
  static const String underWarranty = 'under warranty';
  static const String documentsSection = 'Documents';
  static const String loadDetailError = "Couldn't load this system.";
  static const String detailMissing = 'This system is no longer here.';

  /// Invented: toggling a task from the card failed.
  static const String taskFailed = "Couldn't update that task. Try again.";

  // ── Log a repair or service (invented: the kit draws the button only) ─────
  static const String logTitle = 'Log a repair or service';
  static const String logEditTitle = 'Edit this entry';
  static const String logKind = 'What kind';
  static const String logKindService = 'Service';
  static const String logKindRepair = 'Repair';
  static const String logKindInstalled = 'Installed';
  static const String logKindPurchased = 'Bought';
  static const String logWhat = 'What was done';
  static const String logWhatHint = 'Annual tune-up';
  static const String logWhatRequired = 'Say what was done';
  static const String logDate = 'Date';
  static const String logProvider = 'Who did it';
  static const String logProviderHint = 'Summit Heating & Air';
  static const String logCost = 'Cost';
  static const String logCostInvalid = 'Enter a cost like 129';
  static const String logWarranty = 'Covered by the warranty';
  static const String logWarrantyHelper = 'NO COST TO YOU';
  static const String logNote = 'Note';
  static const String logDocument = 'Receipt or report';
  static const String logSave = 'Save';
  static const String logSaved = 'Added to history.';
  static const String logUpdated = 'History updated.';
  static const String logFailed = "Couldn't save that entry. Try again.";

  /// Formats dollars: "$4,850" or "$129.50".
  static String money(num value) {
    final whole = value == value.roundToDouble();
    return NumberFormat.currency(
      symbol: r'$',
      decimalDigits: whole ? 0 : 2,
    ).format(value);
  }
}
