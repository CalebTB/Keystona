import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'recent_searches_provider.g.dart';

/// The last few things the user searched for, newest first. Stored on the
/// device only.
@riverpod
class RecentSearches extends _$RecentSearches {
  /// Most searches remembered.
  static const int limit = 5;

  static const String _key = 'documents_recent_searches';

  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  /// Moves [text] to the front. The list updates first; the write follows.
  Future<void> remember(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final current = state.value ?? const <String>[];
    final next = [
      trimmed,
      ...current.where((s) => s.toLowerCase() != trimmed.toLowerCase()),
    ].take(limit).toList();
    state = AsyncData(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next);
  }
}
