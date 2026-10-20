import 'package:intl/intl.dart';

import 'lifespan/lifespan_reading.dart';
import 'models/appliance.dart';

/// Copy for the Appliances list, Add / Edit an appliance and the appliance
/// detail (kit: HomeAppliances, AddAppliance, ApplianceDetail).
abstract final class ApplianceCopy {
  // ─── List ───────────────────────────────────────────────────────────────

  static const String listBack = 'Home profile';
  static const String listTitle = 'Appliances';
  static const String add = '+ Add';
  static const String listLoadError = "Couldn't load your appliances.";
  static const String emptyTitle = 'No appliances yet';
  static const String emptyBody =
      'Add your fridge, washer and the rest. We keep their warranties, '
      'manuals and upkeep in one place.';
  static const String emptyAction = 'Add an appliance';
  static const String emptyScan = 'Scan a label';
  static const String oftenForgotten = 'OFTEN FORGOTTEN';
  static const String suggestionNote = 'TRACKING THEM ADDS THEIR UPKEEP REMINDERS';
  static const String scanToAdd = 'Scan a label to add one';
  static const String sortLabel = 'Sort';

  static String allChip(int n) => 'All $n';

  /// "WARRANTY ENDS DEC 9".
  static String warrantyEnds(DateTime d) =>
      'Warranty ends ${DateFormat.MMMd().format(d)}';

  // ─── Add / Edit ─────────────────────────────────────────────────────────

  static const String addEyebrow = 'Home profile · New';
  static const String editEyebrow = 'Home profile · Edit';
  static const String addTitle = 'Add an appliance.';
  static String editTitle(String name) => 'Edit $name.';
  static const String backToScan = 'Scan';
  static const String backToList = 'Appliances';
  static const String cancel = 'Cancel';
  static const String save = 'Save appliance';
  static const String saveEdit = 'Save changes';
  static const String requiredNote = 'REQUIRED * · EVERYTHING ELSE CAN WAIT';

  static String scanRead(int n) =>
      'We read $n ${n == 1 ? 'field' : 'fields'} from the label';
  static const String scanBodyBefore = 'The ones edged in ';
  static const String scanBodyBlue = 'blue';
  static const String scanBodyAfter = ' came from it — check them, then save.';
  static const String rescan = 'Rescan';

  static const String category = 'Category';
  static const String name = 'Name';
  static const String nameHint = 'Your name for it — e.g. "Main fridge"';
  static const String nameRequired = 'Give it a name';
  static const String identification = 'Identification';
  static const String brand = 'Brand';
  static const String model = 'Model';
  static const String serial = 'Serial number';
  static const String color = 'Color';
  static const String colorHint = 'White';
  static const String purchase = 'Purchase';
  static const String price = 'Price';
  static const String priceHint = r'$  0';
  static const String retailer = 'Retailer';
  static const String retailerHint = 'Where from';
  static const String purchaseDate = 'Purchase date';
  static const String dateHint = 'MM / DD / YYYY';
  static const String dateInvalid = 'Use month / day / year';
  static const String priceInvalid = 'Numbers only';
  static const String hasWarranty = 'It has a warranty';
  static const String hasWarrantyHelper = "We'll track the expiration date";
  static const String warrantyProvider = 'Provider';
  static const String warrantyExpires = 'Expires';
  static const String linkWarranty = 'Link the warranty from Docs';
  static String warrantyLinked(String doc) => 'Linked: $doc';
  static const String warrantyDocFallback = 'warranty document';
  static const String photoOfWhat = 'What is it a photo of?';
  static const String specifications = 'Specifications';
  static const String specsHide = 'HIDE';
  static String specsScanned(int n) => '$n SCANNED';
  static const String specsShow = 'SHOW';
  static const String capacity = 'Capacity';
  static const String capacityHint = '4.5';
  static const String type = 'Type';
  static const String energyStar = 'ENERGY STAR certified';
  static const String energyStarHelper = 'Read from the label';
  static const String photos = 'Photos';
  static const String photoLabelTag = 'LABEL';
  static const String photoRemove = 'Remove photo';
  static const String addPhotoSemantics = 'Add a photo';
  static const String freeNote = 'FREE PLAN · 4 PHOTOS';
  static const String premiumNote = 'PREMIUM · EVERY PHOTO IS KEPT';
  static const String labelSaved = 'THE LABEL PHOTO IS SAVED FOR YOU';

  static const String moreDetails = 'More details';
  static const String location = 'Location';
  static const String locationHint = 'Laundry room';
  static const String status = 'Status';
  static const String expectedLife = 'Expected life (years)';
  static const String expectedLifeHelper = 'Typical for this kind of appliance';
  static const String notes = 'Notes';

  static const String delete = 'Delete this appliance';
  static const String deleteTitle = 'Delete this appliance?';
  static String deleteBody(String name) =>
      '$name and its reminders come off your list. You can undo for a few '
      'seconds.';
  static const String deleteConfirm = 'Delete';
  static String deleted(String name) => 'Deleted $name';
  static const String deleteError = "Couldn't delete that. Try again.";
  static const String restoreError = "Couldn't bring it back. Try again.";
  static const String saveError = "Couldn't save that. Try again.";
  static const String added = 'Appliance added.';
  static const String updated = 'Appliance updated.';

  // ─── Detail ─────────────────────────────────────────────────────────────

  static const String detailBack = 'Appliances';
  static const String edit = 'Edit';
  static const String healthy = 'Healthy';
  static const String needsRepair = 'Needs repair';
  static const String replaced = 'Replaced';
  static const String removed = 'Removed';
  static const String detailLoadError = "Couldn't load this appliance.";
  static const String notFoundTitle = 'We can’t find that appliance';
  static const String notFoundBody =
      'It may have been deleted. Head back to your appliances.';

  static String eyebrow(Appliance a) =>
      '${a.category.label} · Appliance'.toUpperCase();

  static const String unitTag = 'UNIT';
  static String photoBadge(int n) => '$n ${n == 1 ? 'PHOTO' : 'PHOTOS'}';

  static const String lifespan = 'LIFESPAN';
  static String bought(DateTime d) =>
      'BOUGHT ${DateFormat.yMMM().format(d).toUpperCase()}';

  static const String nextUp = 'Next up';
  static const String addTask = 'Add a task';
  static const String addPhotoBadge = 'ADD A PHOTO';
  static const String lifespanNeedsDate =
      'Add the purchase date to see how much life is left.';
  static const String atEndOfLife = 'At end of life';
  static const String aging = 'Aging';
  static const String pastLife = 'Past expected life';
  static String nextUpTitle(int n) => 'Next up · $n';
  static String allTasks(int n) => 'All $n appliance ${n == 1 ? 'task' : 'tasks'}';

  static const String purchaseTitle = 'Purchase';
  static const String priceLabel = 'Price';
  static const String fromLabel = 'From';
  static const String boughtLabel = 'Bought';
  static const String warrantyLabel = 'Warranty';
  static const String identificationTitle = 'Identification';
  static const String serialLabel = 'Serial';

  static String specsTitle(int n) => 'Specifications · $n';

  static String historyTitle(int n) => 'History · $n';
  static String historySince(double total, int year) =>
      '${NumberFormat.currency(symbol: r'$', decimalDigits: 0).format(total)} since $year';
  static const String logService = 'Log a repair or service';
  static const String boughtEntry = 'Bought';
  static String documentsTitle(int n) => 'Documents · $n';

  // Warranty callout
  static String warrantyEndsIn(int days) =>
      'Warranty ends in $days ${days == 1 ? 'day' : 'days'}';
  static String coveredUntil(DateTime d) =>
      'Covered until ${DateFormat.MMMd().format(d)}.';
  static const String warrantyBody =
      'Any noise, leaks or slow draining? Get it looked at while repairs are '
      'still free.';
  static String addCheck(DateTime d) =>
      'Add a check before ${DateFormat.MMMd().format(d)}';
  static String checkAdded(DateTime due) =>
      '✓ Added to Tasks · ${DateFormat.MMMd().format(due)}';
  static const String checkError = "Couldn't change that task. Try again.";

  // ─── Care tips under the lifespan bar ───────────────────────────────────

  /// The closing sentence of the lifespan card: how long is left, then a care
  /// tip for the kind of appliance.
  static String lifespanBody(LifespanReading reading) {
    final left = reading.yearsLeft;
    if (left == null) return '';
    if (left < 0) {
      return 'Past its expected life by about ${_years(-left)}. '
          'Start planning a replacement.';
    }
    return 'About ${_years(left)} left.';
  }

  /// "8 years", "9½ years", "1 year": to the nearest half.
  static String years(double value) => _years(value);

  static String _years(double value) {
    final halves = (value * 2).round();
    final whole = halves ~/ 2;
    final half = halves.isOdd ? '½' : '';
    final unit = halves == 2 ? 'year' : 'years';
    return '$whole$half $unit';
  }
}
