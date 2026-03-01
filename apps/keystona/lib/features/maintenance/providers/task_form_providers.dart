import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';

part 'task_form_providers.g.dart';

/// A simple name + id pair for picker dropdowns.
typedef PickerOption = ({String id, String name});

/// Fetches all non-deleted systems for the given property.
///
/// Used by [TaskFormScreen] to populate the "Link to system" picker.
/// Auto-disposed when the form is closed.
@riverpod
Future<List<PickerOption>> systemPickerOptions(
  Ref ref,
  String propertyId,
) async {
  final rows = await SupabaseService.client
      .from('systems')
      .select('id, name')
      .eq('property_id', propertyId)
      .isFilter('deleted_at', null)
      .order('name', ascending: true);

  return rows
      .map<PickerOption>((r) => (id: r['id'] as String, name: r['name'] as String))
      .toList();
}

/// Fetches all non-deleted appliances for the given property.
///
/// Used by [TaskFormScreen] to populate the "Link to appliance" picker.
/// Auto-disposed when the form is closed.
@riverpod
Future<List<PickerOption>> appliancePickerOptions(
  Ref ref,
  String propertyId,
) async {
  final rows = await SupabaseService.client
      .from('appliances')
      .select('id, name')
      .eq('property_id', propertyId)
      .isFilter('deleted_at', null)
      .order('name', ascending: true);

  return rows
      .map<PickerOption>((r) => (id: r['id'] as String, name: r['name'] as String))
      .toList();
}
