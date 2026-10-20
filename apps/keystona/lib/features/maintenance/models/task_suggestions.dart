import 'task_draft.dart';
import 'task_form_options.dart';
import 'task_link_option.dart';

/// A one-tap starting point on the Add a task form: it fills the name, and
/// for the common ones the item, how often, who and the optional details.
class TaskSuggestion {
  const TaskSuggestion({
    required this.label,
    this.itemHint,
    this.frequency,
    this.who,
    this.minutes,
    this.cost,
    this.supplies,
  });

  final String label;

  /// Word found in the name of the item it usually belongs to.
  final String? itemHint;
  final TaskFrequency? frequency;
  final TaskWho? who;
  final int? minutes;
  final String? cost;
  final String? supplies;
}

/// Suggestion copy and the rules for which to show (kit: AddTask).
abstract final class TaskSuggestions {
  static const String commonTitle = 'Common tasks · tap to fill in';

  /// Most chips shown at once.
  static const int maxShown = 4;

  static const List<TaskSuggestion> common = [
    TaskSuggestion(
      label: 'Replace HVAC air filter',
      itemHint: 'furnace',
      frequency: TaskFrequency.everyThreeMonths,
      who: TaskWho.me,
      minutes: 15,
      cost: '25',
      supplies: '16×25×1 filter, MERV 8',
    ),
    TaskSuggestion(
      label: 'Clean gutters',
      itemHint: 'gutter',
      frequency: TaskFrequency.twiceAYear,
      who: TaskWho.either,
      minutes: 60,
    ),
    TaskSuggestion(
      label: 'Flush water heater',
      itemHint: 'water heater',
      frequency: TaskFrequency.yearly,
      who: TaskWho.me,
      minutes: 45,
      supplies: 'Garden hose, bucket',
    ),
    TaskSuggestion(
      label: 'Clean dryer vent',
      itemHint: 'dryer',
      frequency: TaskFrequency.yearly,
      who: TaskWho.me,
      minutes: 30,
    ),
  ];

  /// Usual jobs by the word in an item's name.
  static const Map<String, List<String>> usual = {
    'furnace': [
      'Replace HVAC air filter',
      'Service the furnace',
      'Clean the burners',
    ],
    'water heater': [
      'Flush water heater',
      'Check the anode rod',
      'Test the relief valve',
    ],
    'roof': ['Inspect roof flashing', 'Look for missing shingles'],
    'gutter': ['Clean gutters', 'Check downspouts drain away'],
    'panel': ['Label the breakers', 'Test GFCI outlets'],
    'washer': [
      'Wipe the door gasket',
      'Clean the drain filter',
      'Check hoses for bulges',
    ],
    'dryer': ['Clean dryer vent', 'Clean the lint trap housing'],
    'dishwasher': ['Clean the dishwasher filter', 'Run a cleaning cycle'],
    'refrigerator': ['Clean refrigerator coils', 'Replace the water filter'],
    'range hood': ['Clean range hood filter'],
  };

  /// "Usual for the furnace" once an item is chosen.
  static String usualTitle(String itemName) =>
      'Usual for the ${itemName.toLowerCase()}';

  static List<String> _usualFor(TaskLinkOption item) {
    for (final entry in usual.entries) {
      if (item.matches(entry.key)) return entry.value;
    }
    return const [];
  }

  /// Chip labels to show for [draft]: the item's usual jobs once one is
  /// chosen, otherwise the common ones. Empty when nothing should show.
  static List<String> shown(TaskDraft draft) {
    final item = draft.link;
    final name = draft.name.trim();
    final pool = item == null
        ? [for (final s in common) s.label]
        : _usualFor(item);
    final labels = pool.where((l) => l != name).take(maxShown).toList();
    if (item == null) return name.isEmpty ? labels : const [];
    final nameIsUsual = _usualFor(item).contains(draft.name);
    return labels.isNotEmpty && !nameIsUsual ? labels : const [];
  }

  /// The heading above the chips returned by [shown].
  static String titleFor(TaskDraft draft) =>
      draft.link == null ? commonTitle : usualTitle(draft.link!.name);

  /// [draft] after tapping the chip [label].
  static TaskDraft apply(
    TaskDraft draft,
    String label,
    List<TaskLinkOption> options,
  ) {
    final match = common.where((s) => s.label == label);
    if (match.isEmpty) return draft.copyWith(name: label);
    final s = match.first;
    final hint = s.itemHint;
    final item = hint == null
        ? draft.link
        : options.where((o) => o.matches(hint)).firstOrNull ?? draft.link;
    return draft.copyWith(
      name: s.label,
      link: item,
      frequency: s.frequency,
      who: s.who,
      minutes: s.minutes ?? draft.minutes,
      cost: s.cost,
      supplies: s.supplies,
    );
  }
}
