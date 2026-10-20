import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_motion.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_a.dart';
import '../../tasks_copy.dart';

/// "Search or pick a system": filters the task list by name, area or system.
/// Typing is debounced so the list is not rebuilt on every key.
class TasksSearchField extends StatefulWidget {
  const TasksSearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<TasksSearchField> createState() => _TasksSearchFieldState();
}

class _TasksSearchFieldState extends State<TasksSearchField> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      AuroraDurations.searchDebounce,
      () => widget.onChanged(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Semantics(
      textField: true,
      label: TasksCopy.searchSemantics,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraSizes.minTouch),
        ),
        padding: a.symmetric(horizontal: AuroraSpacing.space6),
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.md,
          border: Border.all(
            color: AuroraColors.inkBorder,
            width: AuroraBorders.regular,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: a.of(AuroraTasksA.searchGlyph),
              color: AuroraColors.inkPlaceholder,
            ),
            SizedBox(width: a.of(AuroraSpacing.space4)),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                style: AuroraTasksAType.searchInput,
                cursorColor: AuroraColors.cobalt,
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: TasksCopy.searchHint,
                  hintStyle: AuroraTasksAType.searchHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
