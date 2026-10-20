import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/supabase_system_documents_repository.dart';
import '../repositories/supabase_system_photos_repository.dart';
import '../repositories/supabase_systems_repository.dart';
import '../repositories/system_documents_repository.dart';
import '../repositories/system_photos_repository.dart';
import '../repositories/systems_repository.dart';

/// The data sources behind the Systems screens. Tests override them.
final systemsRepositoryProvider = Provider<SystemsRepository>(
  (ref) => const SupabaseSystemsRepository(),
);

final systemPhotosRepositoryProvider = Provider<SystemPhotosRepository>(
  (ref) => const SupabaseSystemPhotosRepository(),
);

final systemDocumentsRepositoryProvider = Provider<SystemDocumentsRepository>(
  (ref) => const SupabaseSystemDocumentsRepository(),
);
