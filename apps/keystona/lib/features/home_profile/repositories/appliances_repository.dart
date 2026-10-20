import '../models/appliance.dart';

/// Reads and writes the home's appliances.
///
/// Notifiers depend on this interface through `appliancesRepositoryProvider`;
/// tests override it with a fake.
abstract interface class AppliancesRepository {
  /// Every appliance of the home, by category then name.
  Future<List<Appliance>> list();

  /// One appliance, or null when it does not exist (or was deleted).
  Future<Appliance?> get(String id);

  /// Inserts [fields] for the signed-in user's home and returns the new id.
  Future<String> add(Map<String, dynamic> fields);

  /// Writes the changed [fields] of [id].
  Future<void> update(String id, Map<String, dynamic> fields);

  /// Deletes [id] (`soft_delete_appliance`). Undo with [restore].
  Future<void> softDelete(String id);

  /// Brings a deleted appliance back (`restore_appliance`).
  Future<void> restore(String id);

  /// First line of the home's address, for the list's eyebrow.
  Future<String?> addressLine();
}
