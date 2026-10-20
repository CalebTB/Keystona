import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../repositories/home_items_repository.dart';
import '../repositories/property_repository.dart';
import '../repositories/supabase_home_items_repository.dart';
import '../repositories/supabase_property_repository.dart';

part 'home_repositories.g.dart';

/// Data-access seams for the Home profile overview, edit and lifespan
/// screens. Tests override them with fakes.
@riverpod
PropertyRepository propertyRepository(Ref ref) =>
    SupabasePropertyRepository(SupabaseService.client);

@riverpod
HomeItemsRepository homeItemsRepository(Ref ref) =>
    SupabaseHomeItemsRepository(SupabaseService.client);
