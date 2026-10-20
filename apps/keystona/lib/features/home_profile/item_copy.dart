import 'package:intl/intl.dart';

import 'models/item_ref.dart';
import 'models/item_summary.dart';

/// Copy for the screens that serve both systems and appliances: tasks,
/// photos and reminders (kit: ItemTasks, ItemPhotos, ItemReminders). The kit
/// draws them for a furnace; the wording takes the item's name.
abstract final class ItemCopy {
  // ─── Shared ─────────────────────────────────────────────────────────────

  static const String loadError = "Couldn't load that. Check your connection.";
  static const String notFoundTitle = 'We can’t find that';
  static const String notFoundBody =
      'It may have been deleted. Head back and pick another.';
  static const String back = 'Back';
  static const String saveError = "Couldn't save that. Try again.";

  // ─── ItemTasks ──────────────────────────────────────────────────────────

  static const String manage = 'Manage';

  static String tasksTitle(ItemSummary item) => '${item.name} tasks';

  static String comingUpTab(int n) => 'Coming up · $n';
  static String doneTab(int n) => 'Done · $n';

  static String addTask(ItemSummary item) => 'Add a ${item.lowerName} task';

  static const String onSchedule = 'ON SCHEDULE';

  static String earlier(int n, DateTime since) =>
      '+ $n EARLIER · BACK TO ${DateFormat.yMMM().format(since).toUpperCase()}';

  static const String upEmptyTitle = 'Nothing coming up';
  static String upEmptyBody(ItemSummary item) =>
      'Add a task for the ${item.lowerName} and it shows up here.';
  static const String doneEmptyTitle = 'Nothing done yet';
  static String doneEmptyBody(ItemSummary item) =>
      'Finished ${item.lowerName} tasks show up here.';

  static String markDone(String name) => 'Mark done: $name';

  static String deletedTask(String name) => 'Deleted: $name';

  // ─── ItemPhotos ─────────────────────────────────────────────────────────

  static const String photosTitle = 'Photos';
  static const String addPhoto = 'Add';
  static const String addPhotoSemantics = 'Add a photo';
  static const String expandSemantics = 'Open the photo';
  static const String previousPhoto = 'Previous photo';
  static const String nextPhoto = 'Next photo';
  static const String goodPhotos = 'GOOD PHOTOS TO HAVE';
  static const String photosEmptyTitle = 'No photos yet';
  static String photosEmptyBody(ItemSummary item) =>
      'Add one of the ${item.lowerName}’s label and one of the whole thing.';
  static const String photoOfWhat = 'What is it a photo of?';
  static const String removePhoto = 'Remove photo';
  static const String removePhotoTitle = 'Remove this photo?';
  static const String removePhotoBody =
      'It’s taken off for good. You can add it again any time.';
  static const String removeConfirm = 'Remove';
  static const String photoRemoved = 'Photo removed';
  static const String photoError = "Couldn't save that photo. Try again.";
  static const String removeError = "Couldn't remove that photo. Try again.";

  static String positionOf(int index, int total) => '$index OF $total';

  static String freePhotos(int count, int limit) =>
      '$count of $limit photos on Free';

  static String premiumPhotos(int count) =>
      '$count ${count == 1 ? 'photo' : 'photos'}';

  static const String freePhotosNote = 'PREMIUM KEEPS EVERY PHOTO';
  static const String premiumPhotosNote = 'PREMIUM KEEPS EVERY PHOTO';

  static const String upgradeHeadline = 'Keep every photo';
  static const String upgradeReason =
      'Free accounts keep up to 4 photos of each system or appliance.';
  static const List<String> upgradeFeatures = [
    'Unlimited photos on every system and appliance',
    'Unlimited documents',
    'Full-text document search',
  ];
  static const String upgradeKey = 'item_photo_limit';

  /// The caption under the big photo when the person gave none.
  static String defaultCaption(String typeValue) => switch (typeValue) {
    'label' => 'Rating label',
    'filter' => 'Filter slot',
    'repair' => 'Repair',
    _ => 'The unit',
  };

  // ─── ItemReminders ──────────────────────────────────────────────────────

  static const String done = 'Done';

  static String remindersTitle(ItemSummary item) => '${item.name} reminders';

  static String backToTasks(ItemSummary item) => '${item.name} tasks';

  static String remindersBlurb(ItemSummary item) =>
      'Turn off anything that doesn’t fit your ${item.lowerName}, or change '
      'how often it comes up. Turned-off reminders don’t count toward Home '
      'Health.';

  static String onTitle(int n) => 'On · $n';
  static const String onNote = 'Shows in your tasks';
  static String offTitle(int n) => 'Turned off · $n';
  static const String offNote = 'Hidden everywhere';

  static String addOwn(ItemSummary item) =>
      'Add your own ${item.lowerName} task';

  static String suggestionsNote(ItemSummary item) => item.item.kind ==
          ItemKind.system
      ? 'Suggestions come from the ${item.lowerName} type, its age and your '
            'climate'
      : 'Suggestions come from the ${item.lowerName} type and how old it is';

  static const String remindersEmptyTitle = 'No reminders yet';
  static String remindersEmptyBody(ItemSummary item) =>
      'Add a task for the ${item.lowerName} and its reminder shows up here.';
}
