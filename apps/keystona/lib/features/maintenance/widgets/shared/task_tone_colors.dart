import 'package:flutter/painting.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../services/task_due.dart';

/// Ring and text colors for how urgent a task is: overdue is coral, soon is
/// amber, later is cobalt. The word always accompanies the color.
extension TaskDueToneColors on TaskDueTone {
  Color get ring => switch (this) {
    TaskDueTone.overdue => AuroraColors.coral,
    TaskDueTone.soon => AuroraColors.amber,
    TaskDueTone.later => AuroraColors.cobalt,
  };

  Color get text => switch (this) {
    TaskDueTone.overdue => AuroraColors.coralDeep,
    TaskDueTone.soon => AuroraColors.amberDeep,
    TaskDueTone.later => AuroraColors.cobaltDeep,
  };
}
