/// Aurora design kit — durations and opacities that are not colors.
abstract final class AuroraDurations {
  /// Coral overdue-dot pulse (`kpulse`).
  static const Duration pulse = Duration(milliseconds: 1800);

  /// Shimmer sweep for skeletons.
  static const Duration shimmer = Duration(milliseconds: 1200);

  /// Standard UI transition (tab content, chip select).
  static const Duration fast = Duration(milliseconds: 200);

  /// Switch knob slide.
  static const Duration switchToggle = Duration(milliseconds: 150);

  /// Pressed-state feedback on tappable surfaces.
  static const Duration press = Duration(milliseconds: 100);

  /// Sheet and modal transition.
  static const Duration sheet = Duration(milliseconds: 300);

  /// Undo snackbar for everyday actions: mark done, skip, push back, stop
  /// reminders. (The kit notes say 5 s.)
  static const Duration undo = Duration(seconds: 5);

  /// Undo snackbar after a DELETE: longer, because a delete reads as final
  /// (the ConfirmDelete storyboard says 10 s). Decided 2026-10-20.
  static const Duration undoDelete = Duration(seconds: 10);

  /// Debounce for search input.
  static const Duration searchDebounce = Duration(milliseconds: 300);
}

abstract final class AuroraOpacity {
  /// Ghosted example cards in showcase empty states.
  static const double ghost = 0.5;

  /// Pressed tappable surface.
  static const double pressed = 0.6;

  /// Disabled control content.
  static const double disabled = 0.35;
}

/// Snackbar visibility by severity (non-undo toasts).
abstract final class AuroraSnackbarDurations {
  static const Duration success = Duration(milliseconds: 2500);
  static const Duration info = Duration(milliseconds: 3500);
  static const Duration warning = Duration(milliseconds: 4500);

  /// Errors stay long enough to read and retry.
  static const Duration error = Duration(seconds: 10);
}
