import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_a.dart';
import '../../../../core/theme/aurora_motion.dart';
import '../../../../core/theme/aurora_scale.dart';

/// The coral dot before "EXPIRING SOON". A ring grows out of it and fades,
/// unless the system asks for reduced motion.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AuroraDurations.pulse,
  );

  @override
  void initState() {
    super.initState();
    // Starting the repeat after the first frame avoids a startup assertion on
    // pushed routes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final size = a.of(AuroraDocsA.pulseDot);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = reduceMotion ? 0.0 : _controller.value;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuroraColors.coral,
              boxShadow: [
                BoxShadow(
                  color: AuroraColors.coral.withValues(
                    alpha: (1 - t) * AuroraDocsA.pulseStartOpacity,
                  ),
                  spreadRadius: t * a.of(AuroraDocsA.pulseRing),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
