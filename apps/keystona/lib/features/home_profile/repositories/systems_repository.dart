import '../models/property_brief.dart';
import '../models/system.dart';

/// Reads and writes the property's systems.
///
/// Screens and notifiers depend on this interface through
/// `systemsRepositoryProvider`; tests override it with a fake and never reach
/// Supabase.
abstract interface class SystemsRepository {
  /// The user's property facts, null when they have no property yet.
  Future<PropertyBrief?> property();

  /// Every non-deleted system of the property, by category then name.
  Future<List<HomeSystem>> list();

  /// One system by id. Throws when it does not exist or was deleted.
  Future<HomeSystem> fetch(String id);

  /// Inserts a system and returns its id. [fields] are the editable columns;
  /// the repository adds `property_id` and `user_id`.
  Future<String> create(Map<String, dynamic> fields);

  /// Updates columns of one system.
  Future<void> update(String id, Map<String, dynamic> fields);

  /// Soft-deletes through `soft_delete_system`.
  Future<void> softDelete(String id);

  /// Undo of [softDelete], through `restore_system`.
  Future<void> restore(String id);
}
