/// Aurora design kit — durations and opacities that are not colors.
abstract final class AuroraDurations {
  /// Coral overdue-dot pulse (`kpulse`).
  static const Duration pulse = Duration(milliseconds: 1800);

  /// Shimmer sweep for skeletons.
  static const Duration shimmer = Duration(milliseconds: 1200);

  /// Standard UI transition (tab content, chip select).
  static const Duration fast = Duration(milliseconds: 200);

  /// Sheet and modal transition.
  static const Duration sheet = Duration(milliseconds: 300);

  /// Undo snackbar visibility. Kit notes say 5 s; the ConfirmDelete storyboard
  /// says 10 s — see the open item in the plan before changing.
  static const Duration undo = Duration(seconds: 5);

  /// Debounce for search input.
  static const Duration searchDebounce = Duration(milliseconds: 300);
}

abstract final class AuroraOpacity {
  /// Ghosted example cards in showcase empty states.
  static const double ghost = 0.5;

  /// Disabled control content.
  static const double disabled = 0.35;
}
