import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/home_profile/models/item_ref.dart';
import 'package:keystona/features/home_profile/models/item_service_entry.dart';
import 'package:keystona/features/home_profile/providers/item_service_log_provider.dart';
import 'package:keystona/features/home_profile/repositories/item_service_rows.dart';

import 'support/fake_item_service_log_repository.dart';

const furnace = ItemRef.system('s1');
const washer = ItemRef.appliance('a1');

ItemServiceDraft draft({
  String title = 'Annual tune-up',
  DateTime? on,
  double? cost = 129,
  ServiceKind kind = ServiceKind.service,
}) => ItemServiceDraft(
  kind: kind,
  serviceDate: on ?? DateTime(2025, 10, 6),
  title: title,
  provider: 'Summit Heating & Air',
  cost: cost,
  note: 'receipt saved',
  underWarranty: true,
  documentId: 'd1',
);

ItemServiceEntry entry(String id, ItemRef item, DateTime on) => ItemServiceEntry(
  id: id,
  item: item,
  kind: ServiceKind.service,
  serviceDate: on,
  title: 'T $id',
);

void main() {
  group('row builders', () {
    test('insert for a system carries user, property and only system_id', () {
      final row = ItemServiceRows.insert(
        item: furnace,
        propertyId: 'p1',
        userId: 'u1',
        draft: draft(),
      );
      expect(row, {
        'property_id': 'p1',
        'user_id': 'u1',
        'system_id': 's1',
        'appliance_id': null,
        'kind': 'service',
        'service_date': '2025-10-06',
        'title': 'Annual tune-up',
        'provider': 'Summit Heating & Air',
        'cost': 129.0,
        'note': 'receipt saved',
        'under_warranty': true,
        'document_id': 'd1',
      });
      expect(row.containsKey('id'), isFalse);
    });

    test('insert for an appliance sets only appliance_id', () {
      final row = ItemServiceRows.insert(
        item: washer,
        propertyId: 'p1',
        userId: 'u1',
        draft: draft(),
      );
      expect(row['appliance_id'], 'a1');
      expect(row['system_id'], isNull);
    });

    test('DATE columns are YYYY-MM-DD, zero padded', () {
      expect(ItemServiceRows.dateColumn(DateTime(2021, 3, 5)), '2021-03-05');
      final row = ItemServiceRows.update(draft(on: DateTime(2021, 3, 5, 14, 30)));
      expect(row['service_date'], '2021-03-05');
    });

    test('update carries only the editable columns', () {
      expect(ItemServiceRows.update(draft()).keys.toSet(), {
        'kind',
        'service_date',
        'title',
        'provider',
        'cost',
        'note',
        'under_warranty',
        'document_id',
      });
    });

    test('reinsert keeps the old id', () {
      final e = ItemServiceEntry(
        id: 'old-id',
        item: furnace,
        kind: ServiceKind.repair,
        serviceDate: DateTime(2025, 2, 3),
        title: 'Replaced the igniter',
        cost: 210,
        underWarranty: true,
      );
      final row = ItemServiceRows.reinsert(
        entry: e,
        propertyId: 'p1',
        userId: 'u1',
      );
      expect(row['id'], 'old-id');
      expect(row['kind'], 'repair');
      expect(row['user_id'], 'u1');
      expect(row['property_id'], 'p1');
      expect(row['system_id'], 's1');
    });

    test('the column list names every column and never selects *', () {
      final columns = ItemServiceColumns.all.split(', ');
      expect(columns, [
        'id',
        'property_id',
        'user_id',
        'system_id',
        'appliance_id',
        'kind',
        'service_date',
        'title',
        'provider',
        'cost',
        'note',
        'under_warranty',
        'document_id',
        'created_at',
        'updated_at',
      ]);
      expect(ItemServiceColumns.all.contains('*'), isFalse);
    });
  });

  group('entry model', () {
    test('fromRow reads a NUMERIC cost that arrives as int or double', () {
      final base = {
        'id': 'e1',
        'system_id': 's1',
        'appliance_id': null,
        'kind': 'installed',
        'service_date': '2021-03-12',
        'title': 'Installed',
        'under_warranty': false,
      };
      expect(
        ItemServiceEntry.fromRow({...base, 'cost': 4850}).cost,
        4850.0,
      );
      expect(
        ItemServiceEntry.fromRow({...base, 'cost': 129.5}).cost,
        129.5,
      );
      final e = ItemServiceEntry.fromRow({...base, 'cost': null});
      expect(e.cost, isNull);
      expect(e.item, furnace);
      expect(e.kind, ServiceKind.installed);
      expect(e.serviceDate, DateTime(2021, 3, 12));
    });

    test('an appliance row maps to an appliance ref', () {
      final e = ItemServiceEntry.fromRow({
        'id': 'e1',
        'system_id': null,
        'appliance_id': 'a1',
        'kind': 'purchased',
        'service_date': '2023-12-09',
        'title': 'Bought',
      });
      expect(e.item, washer);
      expect(e.kind, ServiceKind.purchased);
    });

    test('unknown kinds fall back to service', () {
      expect(ServiceKind.fromValue('weird'), ServiceKind.service);
    });

    test('newest first, ties by creation time', () {
      final a = entry('a', furnace, DateTime(2025, 2, 3));
      final b = entry('b', furnace, DateTime(2025, 10, 6));
      final list = [a, b]..sort(ItemServiceEntry.newestFirst);
      expect(list.map((e) => e.id), ['b', 'a']);
    });
  });

  group('provider', () {
    ProviderContainer container(FakeItemServiceLogRepository repo) {
      final c = ProviderContainer(
        overrides: [itemServiceLogRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('lists the item newest first and nothing of other items', () async {
      final repo = FakeItemServiceLogRepository([
        entry('old', furnace, DateTime(2021, 3, 12)),
        entry('new', furnace, DateTime(2025, 10, 6)),
        entry('other', washer, DateTime(2024)),
      ]);
      final c = container(repo);
      final list = await c.read(itemServiceLogProvider(furnace).future);
      expect(list.map((e) => e.id), ['new', 'old']);
    });

    test('add waits for the row, then sorts it in', () async {
      final repo = FakeItemServiceLogRepository([
        entry('old', furnace, DateTime(2021, 3, 12)),
      ]);
      final c = container(repo);
      await c.read(itemServiceLogProvider(furnace).future);
      final created = await c
          .read(itemServiceLogProvider(furnace).notifier)
          .add(draft());
      expect(created.id, 'new1');
      expect(
        c.read(itemServiceLogProvider(furnace)).value!.map((e) => e.id),
        ['new1', 'old'],
      );
    });

    test('edit is optimistic and rolls back when the write fails', () async {
      final repo = FakeItemServiceLogRepository([
        entry('e1', furnace, DateTime(2021, 3, 12)),
      ]);
      final c = container(repo);
      await c.read(itemServiceLogProvider(furnace).future);
      final notifier = c.read(itemServiceLogProvider(furnace).notifier);
      final e = c.read(itemServiceLogProvider(furnace)).value!.single;

      repo.failWrites = StateError('nope');
      await expectLater(
        notifier.edit(e, draft(title: 'Changed')),
        throwsA(isA<StateError>()),
      );
      expect(c.read(itemServiceLogProvider(furnace)).value!.single.title, 'T e1');

      repo.failWrites = null;
      await notifier.edit(e, draft(title: 'Changed'));
      expect(
        c.read(itemServiceLogProvider(furnace)).value!.single.title,
        'Changed',
      );
      expect(repo.entries.single.title, 'Changed');
    });

    test('remove then restore (Undo) puts the same id back', () async {
      final repo = FakeItemServiceLogRepository([
        entry('e1', furnace, DateTime(2021, 3, 12)),
        entry('e2', furnace, DateTime(2025, 10, 6)),
      ]);
      final c = container(repo);
      await c.read(itemServiceLogProvider(furnace).future);
      final notifier = c.read(itemServiceLogProvider(furnace).notifier);
      final e2 = c.read(itemServiceLogProvider(furnace)).value!.first;

      await notifier.remove(e2);
      expect(c.read(itemServiceLogProvider(furnace)).value!.map((e) => e.id), [
        'e1',
      ]);
      expect(repo.calls, contains('delete:e2'));

      await notifier.restore(e2);
      expect(c.read(itemServiceLogProvider(furnace)).value!.map((e) => e.id), [
        'e2',
        'e1',
      ]);
      expect(repo.calls, contains('reinsert:e2'));
    });

    test('a failed delete puts the entry back and rethrows', () async {
      final repo = FakeItemServiceLogRepository([
        entry('e1', furnace, DateTime(2021, 3, 12)),
      ]);
      final c = container(repo);
      await c.read(itemServiceLogProvider(furnace).future);
      repo.failWrites = StateError('nope');
      final e = c.read(itemServiceLogProvider(furnace)).value!.single;
      await expectLater(
        c.read(itemServiceLogProvider(furnace).notifier).remove(e),
        throwsA(isA<StateError>()),
      );
      expect(c.read(itemServiceLogProvider(furnace)).value!.length, 1);
    });
  });
}
