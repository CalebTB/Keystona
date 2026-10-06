import 'package:flutter/widgets.dart';

import '../../theme/aurora_motion.dart';
import '../../theme/aurora_sizes.dart';

/// Internal tap surface shared by the Aurora widgets (not exported from the
/// barrel). Aurora has no Material ripple: a press dims the surface instead.
///
/// [enforceTouchTarget] grows the layout box to the 44 pt minimum while the
/// child keeps its drawn size, centered inside it.
class AuroraPressable extends StatefulWidget {
  const AuroraPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.selected,
    this.enforceTouchTarget = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final bool? selected;
  final bool enforceTouchTarget;

  @override
  State<AuroraPressable> createState() => _AuroraPressableState();
}

class _AuroraPressableState extends State<AuroraPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    Widget content = AnimatedOpacity(
      opacity: _pressed ? AuroraOpacity.pressed : 1,
      duration: AuroraDurations.press,
      child: widget.child,
    );
    if (widget.enforceTouchTarget) {
      content = ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AuroraSizes.minTouch,
          minHeight: AuroraSizes.minTouch,
        ),
        child: Align(widthFactor: 1, heightFactor: 1, child: content),
      );
    }
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        child: content,
      ),
    );
  }
}
