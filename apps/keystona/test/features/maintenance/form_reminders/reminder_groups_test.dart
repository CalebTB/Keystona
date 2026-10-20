import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/maintenance/models/reminder_groups.dart';
import 'package:keystona/features/maintenance/models/reminder_item.dart';
import 'package:keystona/features/maintenance/reminders_copy.dart';

import 'form_reminders_support.dart';

void main() {
  final data = kReminders();

  test('house groups: safety, outside, yard, climate; mine is separate', () {
    final groups = ReminderGroups.house(data.items);
    expect(groups.map((g) => g.title), [
      'Safety',
      'Outside',
      'Yard',
      ReminderGroups.climateTitle,
    ]);
    expect(groups[1].items.map((i) => i.id), ['h2', 'h3']);
    expect(groups[1].countLabel, '1 OF 2 ON');
    expect(ReminderGroups.mine(data.items).map((i) => i.id), ['m1']);
  });

  test('items tied to a system never show under the house', () {
    final ids = ReminderGroups.house(
      data.items,
    ).expand((g) => g.items).map((i) => i.id);
    expect(ids, isNot(contains('f1')));
    expect(ids, isNot(contains('m1')));
  });

  test('review: by system then appliance then house, suggestions only', () {
    final groups = ReminderGroups.review(data.items);
    expect(groups.first.title, 'Furnace');
    expect(groups.first.items, hasLength(3));
    expect(groups[1].title, 'Washer');
    expect(groups.last.title, ReminderGroups.climateTitle);
    expect(
      groups.expand((g) => g.items).map((i) => i.id),
      isNot(contains('m1')),
    );
  });

  test('turned off: by system, appliance, then around the house', () {
    final off = data.items.where((i) => !i.enabled);
    final groups = ReminderGroups.turnedOff(off);
    expect(groups.map((g) => g.title), [
      'Furnace',
      'Washer',
      ReminderGroups.aroundTheHouseTitle,
    ]);
    expect(groups[1].itemIsAppliance, isTrue);
    expect(groups[0].itemId, 's-furnace');
    expect(groups[2].items.map((i) => i.id), ['h3', 'h4']);
  });

  test('copy: because you added a/an', () {
    expect(
      RemindersCopy.becauseYouAdded('Furnace'),
      'Because you added a furnace',
    );
    expect(
      RemindersCopy.becauseYouAdded('Attic fan'),
      'Because you added an attic fan',
    );
  });

  test('remindersData helpers change one reminder', () {
    final changed = data.mapItem('f3', (i) => i.copyWith(enabled: true));
    expect(changed.items.firstWhere((i) => i.id == 'f3').enabled, isTrue);
    expect(data.items.firstWhere((i) => i.id == 'f3').enabled, isFalse);
    expect(data.withoutItem('f3').items.any((i) => i.id == 'f3'), isFalse);
  });

  test('isMine is custom and one-time only', () {
    final ReminderItem mine = data.items.last;
    expect(mine.isMine, isTrue);
    expect(data.items.first.isMine, isFalse);
  });
}
