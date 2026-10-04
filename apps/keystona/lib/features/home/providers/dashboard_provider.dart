import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../features/home_profile/models/property.dart';
import '../../../features/home_profile/providers/home_profile_provider.dart';
import '../../../features/maintenance/models/home_health_score.dart';
import '../../../features/maintenance/models/maintenance_task.dart';
import '../../../features/maintenance/providers/home_health_score_provider.dart';
import '../../../features/maintenance/providers/maintenance_tasks_provider.dart';
import '../../../services/supabase_service.dart';

part 'dashboard_provider.g.dart';

// ── Dashboard data model ───────────────────────────────────────────────────────

/// Composite view-model assembled for the Home tab dashboard.
///
/// Plain Dart class — never persisted; assembled in [DashboardNotifier].
class DashboardData {
  const DashboardData({
    required this.firstName,
    required this.property,
    required this.score,
    required this.overdueTasks,
    required this.upcomingTasks,
    required this.systemCount,
    required this.applianceCount,
  });

  /// Display name derived from auth user metadata or email prefix.
  final String firstName;

  /// The user's property — null when not set up yet.
  final Property? property;

  /// Maintenance-pillar health score (empty score when no property yet).
  final HomeHealthScore score;

  /// Tasks that are overdue: status == overdue OR (dueDate < today AND not done/skipped).
  final List<MaintenanceTask> overdueTasks;

  /// Scheduled/pending tasks due in the next 30 days, sorted by dueDate, max 5.
  final List<MaintenanceTask> upcomingTasks;

  /// Total active systems for the property.
  final int systemCount;

  /// Total active appliances for the property.
  final int applianceCount;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Builds [DashboardData] from existing providers.
///
/// Kept alive to avoid re-fetching on every tab switch — the sub-providers
/// handle their own lifecycle.
@riverpod
class DashboardNotifier extends _$DashboardNotifier {
  @override
  Future<DashboardData> build() {
    ref.keepAlive();
    return _buildDashboard();
  }

  /// Invalidates all sub-providers then rebuilds — used by pull-to-refresh.
  Future<void> refresh() async {
    ref.invalidate(homeProfileProvider);
    ref.invalidate(homeHealthScoreProvider);
    ref.invalidate(maintenanceTasksProvider);
    ref.invalidateSelf();
    await future;
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  Future<DashboardData> _buildDashboard() async {
    // Resolve first name from auth metadata.
    final firstName = _resolveFirstName();

    // Fetch home profile — may throw NoPropertyException.
    Property? property;
    int systemCount = 0;
    int applianceCount = 0;
    try {
      final overview = await ref.read(homeProfileProvider.future);
      property = overview.property;
      systemCount = overview.systemCount;
      applianceCount = overview.applianceCount;
    } on NoPropertyException {
      property = null;
    } catch (_) {
      property = null;
    }

    // Fetch health score — returns empty score when no property.
    final score = await ref.read(homeHealthScoreProvider.future);

    // Fetch all tasks.
    final allTasks = await ref.read(maintenanceTasksProvider.future);

    final now = DateTime.now().toLocal();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final thirtyDaysOut = todayMidnight.add(const Duration(days: 30));

    // Overdue: explicit overdue status OR past due date AND not terminal.
    final overdue = allTasks
        .where((t) => _isOverdue(t, todayMidnight))
        .where((t) => t.notificationsEnabled)
        .toList();

    // Upcoming: scheduled/pending AND within 30 days, sorted, max 5.
    final upcoming = allTasks
        .where((t) => _isUpcoming(t, todayMidnight, thirtyDaysOut))
        .where((t) => t.notificationsEnabled)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return DashboardData(
      firstName: firstName,
      property: property,
      score: score,
      overdueTasks: overdue,
      upcomingTasks: upcoming.take(5).toList(),
      systemCount: systemCount,
      applianceCount: applianceCount,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  static String _resolveFirstName() {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return 'there';

    final fullName = user.userMetadata?['full_name'] as String?;
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim().split(' ').first;
    }

    final email = user.email ?? '';
    final prefix = email.split('@').first;
    return prefix.isNotEmpty ? prefix : 'there';
  }

  static bool _isOverdue(MaintenanceTask t, DateTime todayMidnight) {
    if (t.status == TaskStatus.completed || t.status == TaskStatus.skipped) {
      return false;
    }
    return t.status == TaskStatus.overdue ||
        t.dueDate.toLocal().isBefore(todayMidnight);
  }

  static bool _isUpcoming(
    MaintenanceTask t,
    DateTime todayMidnight,
    DateTime thirtyDaysOut,
  ) {
    if (t.status == TaskStatus.completed ||
        t.status == TaskStatus.skipped ||
        t.status == TaskStatus.overdue) {
      return false;
    }
    if (t.dueDate.toLocal().isBefore(todayMidnight)) return false;
    return t.dueDate.toLocal().isBefore(thirtyDaysOut);
  }
}
