/// Which table an item lives in.
enum ItemKind { system, appliance }

/// A reference to one system or one appliance. Value equality, so it works as
/// a provider family key and a map key.
class ItemRef {
  const ItemRef(this.kind, this.id);

  const ItemRef.system(this.id) : kind = ItemKind.system;
  const ItemRef.appliance(this.id) : kind = ItemKind.appliance;

  final ItemKind kind;
  final String id;

  bool get isSystem => kind == ItemKind.system;
  bool get isAppliance => kind == ItemKind.appliance;

  @override
  bool operator ==(Object other) =>
      other is ItemRef && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'ItemRef(${kind.name}, $id)';
}
