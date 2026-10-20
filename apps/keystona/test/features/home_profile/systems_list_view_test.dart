import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/home_profile/models/system.dart';
import 'package:keystona/features/home_profile/models/system_template.dart';
import 'package:keystona/features/home_profile/models/systems_list_view.dart';

import 'support/fake_systems.dart';

void main() {
  final now = DateTime(2026, 10, 4);
  final heater = aSystem(
    'wh',
    name: 'Water heater',
    category: SystemCategory.plumbing,
    installed: '2014-10-01',
    life: 12,
  );
  final panel = aSystem(
    'ep',
    name: 'Electrical panel',
    category: SystemCategory.electrical,
    installed: '1998-04-01',
    life: 40,
  );
  final furnace = aSystem('fu');
  final roof = aSystem(
    'rf',
    name: 'Roof',
    category: SystemCategory.roofing,
    installed: null,
  );
  final all = [furnace, panel, heater, roof];

  test('oldest first sorts by percent of life used, unknown last', () {
    final items = SystemsListView.items(all, now: now);
    expect(items.map((i) => i.system.id), ['wh', 'ep', 'fu', 'rf']);
  });

  test('A-Z sorts by name', () {
    final items = SystemsListView.items(all, sort: SystemSort.az, now: now);
    expect(items.map((i) => i.system.name), [
      'Electrical panel',
      'Furnace',
      'Roof',
      'Water heater',
    ]);
  });

  test('groups: roofing counts as Structure, plumbing as Water', () {
    expect(SystemCategory.roofing.group, SystemGroup.structure);
    expect(SystemCategory.plumbing.group, SystemGroup.water);
    expect(SystemCategory.hvac.group, SystemGroup.heatingCooling);
    expect(SystemCategory.windowsDoors.group, SystemGroup.structure);
    final water = SystemsListView.items(
      all,
      group: SystemGroup.water,
      now: now,
    );
    expect(water.map((i) => i.system.id), ['wh']);
    expect(SystemsListView.groupsPresent(all), [
      SystemGroup.heatingCooling,
      SystemGroup.water,
      SystemGroup.structure,
      SystemGroup.electrical,
    ]);
  });

  test('aging count includes at end of life (the kit: water heater)', () {
    expect(SystemsListView.agingCount(all, now: now), 1);
  });

  test('a warranty ending inside the window is noted, a far one is not', () {
    final near = aSystem('n', warrantyExpiration: '2026-12-09');
    final far = aSystem('f', warrantyExpiration: '2031-03-01');
    final items = SystemsListView.items([near, far], now: now);
    expect(items.firstWhere((i) => i.system.id == 'n').warrantyEndsOn, isNotNull);
    expect(items.firstWhere((i) => i.system.id == 'f').warrantyEndsOn, isNull);
  });

  group('suggestions', () {
    test('skip what is already tracked and respect the limit', () {
      final tracked = [
        aSystem('a', name: 'Plumbing', category: SystemCategory.plumbing),
      ];
      final s = SystemTemplates.suggestionsFor(
        yearBuilt: 1998,
        tracked: tracked,
        limit: 3,
      );
      expect(s.map((t) => t.label), ['Windows', 'Sump pump', 'Insulation']);
    });

    test('a chimney is offered only to homes built before 1990', () {
      final old = SystemTemplates.suggestionsFor(
        yearBuilt: 1975,
        tracked: const [],
        limit: 20,
      );
      final newer = SystemTemplates.suggestionsFor(
        yearBuilt: 2005,
        tracked: const [],
        limit: 20,
      );
      expect(old.map((t) => t.label), contains('Chimney'));
      expect(newer.map((t) => t.label), isNot(contains('Chimney')));
    });
  });
}
