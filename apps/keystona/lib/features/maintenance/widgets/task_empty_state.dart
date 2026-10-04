import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../services/supabase_service.dart';
import '../providers/maintenance_tasks_provider.dart';
import '../../../core/widgets/snackbar_service.dart';

/// Empty state for the Maintenance Calendar — Pattern A (Motivational).
///
/// Shown when the user has no tasks at all (no systems added yet).
///
/// **Copy from Empty States Catalog §2.3:**
/// - Headline: "Stay ahead of home repairs"
/// - Subtitle: "We'll build a personalized maintenance plan based on your
///   home's systems and climate. Add your first system to get started."
/// - CTA: "+ Add a System" → navigates to Home Profile → Add System flow
/// - Secondary CTA: "Generate Tasks" → invokes generate-maintenance-tasks
///   Edge Function for testing / onboarding trigger
class TaskEmptyState extends ConsumerStatefulWidget {
  const TaskEmptyState({super.key, required this.onAddSystem});

  final VoidCallback onAddSystem;

  @override
  ConsumerState<TaskEmptyState> createState() => _TaskEmptyStateState();
}

class _TaskEmptyStateState extends ConsumerState<TaskEmptyState> {
  bool _generating = false;

  Future<void> _generateTasks() async {
    setState(() => _generating = true);
    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session == null) return;

      final propertyRow = await SupabaseService.client
          .from('properties')
          .select('id')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (propertyRow == null) {
        if (mounted) {
          SnackbarService.showError(context, 'No property found.');
        }
        return;
      }

      await SupabaseService.client.functions.invoke(
        'generate-maintenance-tasks',
        body: {'property_id': propertyRow['id'] as String},
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );

      if (mounted) {
        await ref.read(maintenanceTasksProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(context, 'Failed to generate tasks: $e');
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handyman_outlined,
              size: 120,
              color: AuroraColors.coral.withAlpha(180),
            ),
            const SizedBox(height: 16),
            Text(
              'Stay ahead of home repairs',
              style: AuroraType.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "We'll build a personalized maintenance plan based on your "
              "home's systems and climate. Add your first system to get started.",
              style: AuroraType.body.copyWith(
                color: AuroraColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AuroraColors.coral,
                foregroundColor: AuroraColors.paper,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: widget.onAddSystem,
              icon: const Icon(Icons.add),
              label: const Text('Add a System'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AuroraColors.coral,
                side: BorderSide(color: AuroraColors.coral),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: _generating ? null : _generateTasks,
              icon: _generating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(_generating ? 'Generating…' : 'Generate Tasks'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Celebration empty state — shown when the user is all caught up.
///
/// **Copy from Empty States Catalog §2.3 (special state):**
/// - Headline: "All caught up! Nothing due right now"
/// - Subtitle: "Great work keeping your home in shape. We'll let you know
///   when something's coming up."
/// - CTA: None
class TaskCaughtUpState extends StatelessWidget {
  const TaskCaughtUpState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 120,
              color: AuroraColors.limeDeep,
            ),
            const SizedBox(height: 16),
            Text(
              'All caught up! Nothing due right now',
              style: AuroraType.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Great work keeping your home in shape. We'll let you know "
              'when something\'s coming up.',
              style: AuroraType.body.copyWith(
                color: AuroraColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the active filter returns no matching tasks.
class TaskFilterEmptyState extends StatelessWidget {
  const TaskFilterEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: AuroraColors.inkTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No tasks match this filter',
              style: AuroraType.body.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Try selecting a different filter.',
              style: AuroraType.body.copyWith(
                color: AuroraColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
