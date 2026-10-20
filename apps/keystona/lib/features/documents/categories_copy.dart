import '../../core/widgets/upgrade_sheet.dart';

/// Copy for "Your categories" (kit: DocCategories).
abstract final class CategoriesCopy {
  static const String back = 'Documents';
  static const String eyebrow = 'DOCUMENT CATEGORIES';
  static const String premium = '★ PREMIUM';
  static const String title = 'Your categories';
  static const String intro =
      'Make your own for things the standard ones don’t cover. Drag to '
      'reorder — this is the order they show in Docs.';
  static const String loadError = "Couldn't load categories.";

  static String yours(int count, int max) => 'YOURS · $count OF $max';
  static const String newCategory = 'NEW CATEGORY';
  static const String namePlaceholder = 'e.g. Hot tub, Fence, Generator';
  static const String add = 'Add';
  static const String edit = 'Edit';
  static const String dragToReorder = 'Drag to reorder';
  static const String iconLabel = 'Icon';

  static String deleteLabel(String name) => 'Delete $name';
  static String documentsCount(int n) =>
      '$n ${n == 1 ? 'DOCUMENT' : 'DOCUMENTS'}';

  // ─── Delete panel ───────────────────────────────────────────────────────────

  static String deleteTitle(String name) => 'Delete “$name”?';
  static String moveBody(int count) => count == 0
      ? 'It has no documents.'
      : 'Its $count ${count == 1 ? 'document' : 'documents'} '
            'won’t be deleted. Move ${count == 1 ? 'it' : 'them'} to:';
  static const String keepIt = 'Keep it';
  static const String deleteAndMove = 'Delete & move';
  static const String deleteOnly = 'Delete';
  static const String deleted = 'Category deleted';

  // ─── Rename sheet ───────────────────────────────────────────────────────────

  static const String editTitle = 'Edit category';
  static const String save = 'Save';
  static const String nameLabel = 'Name';
  static const String nameRequired = 'Name is required';
  static const String nameTooLong = 'Name must be 50 characters or fewer';
  static const String saveFailed = 'Failed to update category.';
  static const String addFailed = 'Failed to create category.';
  static const String deleteFailed = 'Failed to delete category.';
  static const String reorderFailed = 'Failed to reorder categories.';

  // ─── Standard categories ────────────────────────────────────────────────────

  static String standardTitle(int n) => '$n standard categories';
  static String standardBody(List<String> names) =>
      '${names.join(' · ')}. These can’t be renamed or removed.';

  // ─── Premium gate ───────────────────────────────────────────────────────────

  static const UpgradeSheetConfig premiumSheet = UpgradeSheetConfig(
    headline: 'Make your own categories',
    reason: 'Custom document categories are part of Premium.',
    features: [
      'Your own categories, up to 10',
      'Unlimited document storage',
      'Full-text search across all docs',
    ],
    triggerKey: 'doc_categories',
  );
}
