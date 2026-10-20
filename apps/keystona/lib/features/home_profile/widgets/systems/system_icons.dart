import 'package:flutter/material.dart';

import '../../models/system.dart';

/// The outline glyph of each system category.
abstract final class SystemIcons {
  static IconData forCategory(SystemCategory category) => switch (category) {
    SystemCategory.hvac => Icons.local_fire_department_outlined,
    SystemCategory.plumbing => Icons.water_drop_outlined,
    SystemCategory.electrical => Icons.bolt_outlined,
    SystemCategory.roofing => Icons.home_outlined,
    SystemCategory.foundation => Icons.foundation_outlined,
    SystemCategory.siding => Icons.view_agenda_outlined,
    SystemCategory.windowsDoors => Icons.window_outlined,
    SystemCategory.insulation => Icons.layers_outlined,
    SystemCategory.garage => Icons.garage_outlined,
    SystemCategory.other => Icons.build_outlined,
  };
}
