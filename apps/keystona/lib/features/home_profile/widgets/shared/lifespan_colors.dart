import 'package:flutter/painting.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../lifespan/lifespan_reading.dart';

/// Band colors, one place: bar fill and the text that sits beside it.
extension LifespanReadingColors on LifespanReading {
  /// Bar fill: cobalt while there is plenty of life, amber when aging or at
  /// the end of it, coral once past.
  Color get barColor => switch (band) {
    LifespanBand.past => AuroraColors.coral,
    LifespanBand.aging || LifespanBand.endOfLife => AuroraColors.amber,
    _ => AuroraColors.cobalt,
  };

  /// Text beside the bar (age, status).
  Color get textColor => switch (band) {
    LifespanBand.past => AuroraColors.coralDeep,
    LifespanBand.aging || LifespanBand.endOfLife => AuroraColors.amberDeep,
    _ => AuroraColors.ink,
  };
}
