import 'package:flutter/material.dart';

import '../../models/task_parent.dart';

/// The glyph for what a task belongs to.
extension TaskParentIcon on TaskParentKind {
  IconData get icon => switch (this) {
    TaskParentKind.system => Icons.settings_outlined,
    TaskParentKind.appliance => Icons.kitchen_outlined,
    TaskParentKind.area => Icons.home_outlined,
  };
}
