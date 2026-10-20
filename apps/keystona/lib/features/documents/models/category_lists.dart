import 'document_category.dart';

/// Pure views over the category list used by "Your categories".
class CategoryLists {
  CategoryLists(List<DocumentCategory> all)
    : standard = [
        for (final c in all)
          if (c.isSystem) c,
      ]..sort(_bySortOrder),
      custom = [
        for (final c in all)
          if (!c.isSystem) c,
      ]..sort(_bySortOrder),
      _highestSortOrder = all.fold<int>(
        0,
        (max, c) => c.sortOrder > max ? c.sortOrder : max,
      );

  /// How many categories of their own a user may have.
  static const int maxCustom = 10;

  /// Names offered as the place documents go when a category is deleted,
  /// in the order the kit lists them.
  static const List<String> moveTargetNames = ['Other', 'Manual', 'Receipt'];

  /// Longest category name.
  static const int maxNameLength = 50;

  final List<DocumentCategory> standard;
  final List<DocumentCategory> custom;
  final int _highestSortOrder;

  bool get canAddMore => custom.length < maxCustom;

  /// Sort order for the next category created.
  int get nextSortOrder => _highestSortOrder + 1;

  /// Categories a deleted category's documents can move to.
  List<DocumentCategory> get moveTargets {
    final named = <DocumentCategory>[
      for (final name in moveTargetNames)
        ...standard.where((c) => c.name.toLowerCase() == name.toLowerCase()),
    ];
    if (named.isNotEmpty) return named;
    return standard.take(moveTargetNames.length).toList();
  }

  /// The move target preselected in the delete panel, or null when there are
  /// no standard categories to move to.
  DocumentCategory? get defaultMoveTarget =>
      moveTargets.isEmpty ? null : moveTargets.first;

  /// New `sort_order` per id after dragging [custom] item [oldIndex] to
  /// [newIndex] (the index Flutter's reorderable list reports). The existing
  /// sort-order values are reused, so custom categories keep their place
  /// relative to the standard ones.
  Map<String, int> reorder(int oldIndex, int newIndex) {
    final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final ordered = [...custom];
    final moved = ordered.removeAt(oldIndex);
    ordered.insert(target, moved);
    final slots = [for (final c in custom) c.sortOrder]..sort();
    return {for (var i = 0; i < ordered.length; i++) ordered[i].id: slots[i]};
  }

  static int _bySortOrder(DocumentCategory a, DocumentCategory b) =>
      a.sortOrder.compareTo(b.sortOrder);
}
