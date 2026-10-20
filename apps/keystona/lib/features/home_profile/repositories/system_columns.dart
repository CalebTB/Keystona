/// Column lists for the system queries. One place; every name exists in the
/// `systems` table. Never `SELECT *`.
abstract final class SystemColumns {
  static const String all =
      'id, property_id, user_id, category, system_type, name, status, '
      'brand, model, serial_number, installation_date, purchase_price, '
      'installer, location, expected_lifespan_min, expected_lifespan_max, '
      'lifespan_override, warranty_expiration, warranty_provider, '
      'linked_warranty_doc_id, estimated_replacement_cost, '
      'replaced_by_system_id, specifications, notes, created_at, updated_at, '
      'deleted_at';
}
