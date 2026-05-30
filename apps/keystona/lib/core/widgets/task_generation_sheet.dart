import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/maintenance/providers/maintenance_tasks_provider.dart';
import '../../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A suggested maintenance task returned by the generate-item-tasks function.
class SuggestedTask {
  const SuggestedTask({
    required this.name,
    required this.description,
    required this.category,
    required this.recurrence,
    required this.priority,
    required this.diyOrPro,
    required this.estimatedMinutes,
  });

  factory SuggestedTask.fromJson(Map<String, dynamic> json) {
    return SuggestedTask(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      recurrence: json['recurrence'] as String? ?? 'annual',
      priority: json['priority'] as String? ?? 'medium',
      diyOrPro: json['diyOrPro'] as String? ?? 'diy',
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 30,
    );
  }

  final String name;
  final String description;
  final String category;
  final String recurrence;
  final String priority;
  final String diyOrPro;
  final int estimatedMinutes;
}

/// Fetches task suggestions from the edge function and shows a selection sheet.
/// Returns true if any tasks were added.
Future<bool> showTaskGenerationSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String itemName,
  required String brand,
  required String category,
  required String formType,
  String? linkedSystemId,
  String? linkedApplianceId,
  required String propertyId,
}) async {
  // Show loading dialog with a Skip button so user is never stuck.
  var skipped = false;
  showCupertinoDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CupertinoAlertDialog(
      content: const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(),
            SizedBox(height: 10),
            Text('Generating maintenance tasks…'),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            skipped = true;
            Navigator.of(context, rootNavigator: true).pop();
          },
          child: const Text('Skip'),
        ),
      ],
    ),
  );

  List<SuggestedTask> tasks = [];
  try {
    final session = SupabaseService.client.auth.currentSession;
    if (session == null) throw StateError('Not authenticated');

    final response = await SupabaseService.client.functions
        .invoke(
          'generate-item-tasks',
          body: {
            'name': itemName,
            'brand': brand,
            'category': category,
            'formType': formType,
          },
          headers: {'Authorization': 'Bearer ${session.accessToken}'},
        )
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw Exception('timeout'),
        );

    if (response.data != null) {
      final list = response.data is List
          ? response.data as List
          : jsonDecode(response.data.toString()) as List;
      tasks = list
          .map((e) =>
              SuggestedTask.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
  } catch (_) {
    tasks = [];
  }

  if (!context.mounted || skipped) return false;
  Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

  if (tasks.isEmpty) return false;

  final result = await showCupertinoModalPopup<bool>(
    context: context,
    builder: (_) => _TaskSelectionSheet(
      tasks: tasks,
      ref: ref,
      linkedSystemId: linkedSystemId,
      linkedApplianceId: linkedApplianceId,
      propertyId: propertyId,
      category: category,
    ),
  );

  return result == true;
}

// ── Selection sheet ────────────────────────────────────────────────────────────

class _TaskSelectionSheet extends StatefulWidget {
  const _TaskSelectionSheet({
    required this.tasks,
    required this.ref,
    required this.propertyId,
    required this.category,
    this.linkedSystemId,
    this.linkedApplianceId,
  });

  final List<SuggestedTask> tasks;
  final WidgetRef ref;
  final String? linkedSystemId;
  final String? linkedApplianceId;
  final String propertyId;
  final String category;

  @override
  State<_TaskSelectionSheet> createState() => _TaskSelectionSheetState();
}

class _TaskSelectionSheetState extends State<_TaskSelectionSheet> {
  late final List<bool> _selected;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _selected = List.filled(widget.tasks.length, true);
  }

  int get _selectedCount => _selected.where((v) => v).length;

  String _nextDueDate(String recurrence) {
    final now = DateTime.now();
    final due = switch (recurrence) {
      'monthly' => DateTime(now.year, now.month + 1, now.day),
      'quarterly' => DateTime(now.year, now.month + 3, now.day),
      'biannual' => DateTime(now.year, now.month + 6, now.day),
      'annual' => DateTime(now.year + 1, now.month, now.day),
      _ => DateTime(now.year, now.month + 1, now.day),
    };
    final d = due.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _addTasks() async {
    setState(() => _adding = true);
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;

    for (int i = 0; i < widget.tasks.length; i++) {
      if (!_selected[i]) continue;
      final t = widget.tasks[i];
      await widget.ref.read(maintenanceTasksProvider.notifier).addTask({
        'property_id': widget.propertyId,
        'user_id': user.id,
        'task_origin': 'system_generated',
        'name': t.name,
        'description': t.description,
        'category': t.category,
        'due_date': _nextDueDate(t.recurrence),
        'recurrence': t.recurrence,
        'status': 'scheduled',
        'priority': t.priority,
        'difficulty': 'easy',
        'diy_or_pro': t.diyOrPro,
        'estimated_minutes': t.estimatedMinutes,
        if (widget.linkedSystemId != null)
          'linked_system_id': widget.linkedSystemId,
        if (widget.linkedApplianceId != null)
          'linked_appliance_id': widget.linkedApplianceId,
        'reminder_days_before': 7,
        'notifications_enabled': true,
      });
    }

    if (mounted) Navigator.of(context, rootNavigator: true).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.deepNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.task_alt_outlined,
                          color: AppColors.deepNavy, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Suggested Tasks',
                            style: AppTextStyles.bodyMediumSemibold),
                        Text(
                          'Select which tasks to add',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Task list
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: widget.tasks.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 56),
                  itemBuilder: (_, i) {
                    final t = widget.tasks[i];
                    return CheckboxListTile(
                      value: _selected[i],
                      onChanged: (v) =>
                          setState(() => _selected[i] = v ?? false),
                      activeColor: AppColors.deepNavy,
                      title: Text(t.name,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontSize: 14)),
                      subtitle: Text(
                        '${_recurrenceLabel(t.recurrence)} · '
                        '${t.diyOrPro.toUpperCase()} · '
                        '~${t.estimatedMinutes}min',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: Colors.transparent,
                        onPressed: _adding
                            ? null
                            : () => Navigator.of(context,
                                    rootNavigator: true)
                                .pop(false),
                        child: Text(
                          'Skip',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: _selectedCount == 0 || _adding
                            ? AppColors.gray300
                            : AppColors.deepNavy,
                        borderRadius: BorderRadius.circular(12),
                        onPressed:
                            _selectedCount == 0 || _adding ? null : _addTasks,
                        child: _adding
                            ? const CupertinoActivityIndicator(
                                color: Colors.white)
                            : Text(
                                'Add $_selectedCount Task${_selectedCount == 1 ? '' : 's'}',
                                style:
                                    AppTextStyles.bodyMediumSemibold.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _recurrenceLabel(String r) => switch (r) {
        'monthly' => 'Monthly',
        'quarterly' => 'Quarterly',
        'biannual' => 'Every 6 mo',
        'annual' => 'Annual',
        _ => 'One-time',
      };
}
