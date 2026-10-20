import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/home_profile/models/item_ref.dart';

void main() {
  test('value equality and hashing', () {
    expect(const ItemRef.system('a'), const ItemRef(ItemKind.system, 'a'));
    expect(const ItemRef.system('a').hashCode, const ItemRef.system('a').hashCode);
    expect(const ItemRef.system('a') == const ItemRef.appliance('a'), isFalse);
    expect(const ItemRef.system('a') == const ItemRef.system('b'), isFalse);
    final map = {const ItemRef.system('a'): 1};
    expect(map[const ItemRef.system('a')], 1);
    expect(map[const ItemRef.appliance('a')], isNull);
  });

  test('kind helpers', () {
    expect(const ItemRef.system('a').isSystem, isTrue);
    expect(const ItemRef.appliance('a').isAppliance, isTrue);
  });
}
