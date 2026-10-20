import 'package:flutter/foundation.dart';

import '../../models/item_ref.dart';

/// Where each tap on the Home profile goes. The screen decides the route; the
/// widgets only call these.
class ProfileActions {
  const ProfileActions({
    required this.onEdit,
    required this.onOpenSystem,
    required this.onAllSystems,
    required this.onAppliances,
    required this.onScan,
    required this.onAround,
    required this.onLifespan,
    required this.onTasks,
  });

  final VoidCallback onEdit;
  final ValueChanged<ItemRef> onOpenSystem;
  final VoidCallback onAllSystems;
  final VoidCallback onAppliances;
  final VoidCallback onScan;
  final VoidCallback onAround;
  final VoidCallback onLifespan;
  final VoidCallback onTasks;
}
