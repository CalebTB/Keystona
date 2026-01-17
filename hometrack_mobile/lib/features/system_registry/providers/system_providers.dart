import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_system.dart';
import '../models/system_result.dart';
import '../services/system_service.dart';

// Service provider
final systemServiceProvider = Provider<SystemService>((ref) {
  return SystemService();
});

// Property systems provider
final propertySystemsProvider =
    FutureProvider.family<List<HomeSystem>, String>((ref, propertyId) async {
  final service = ref.watch(systemServiceProvider);
  final result = await service.getSystemsForProperty(propertyId);

  return switch (result) {
    SystemSuccess(:final data) => data,
    SystemFailure(:final error) => throw error,
  };
});

// Selected system for detail view
final selectedSystemProvider = StateProvider<HomeSystem?>((ref) => null);
