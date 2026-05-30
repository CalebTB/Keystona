import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/maintenance_task.dart';

const _kSuccessGreen = Color(0xFF34C759);

/// A single task card in the Daily agenda view.
///
/// Tapping the card navigates to task detail.
/// Tapping the circle runs a 3-stage completion animation before calling
/// [onQuickComplete]: green fill + elastic checkmark → content dim/strikethrough
/// → card collapses to zero height.
class AgendaTaskCard extends StatefulWidget {
  const AgendaTaskCard({
    super.key,
    required this.task,
    required this.onQuickComplete,
    this.showDate = false,
  });

  final MaintenanceTask task;
  final VoidCallback onQuickComplete;
  /// When true, shows the task's due date below the category line.
  /// Pass true when displaying cards for a non-today date.
  final bool showDate;

  @override
  State<AgendaTaskCard> createState() => _AgendaTaskCardState();
}

class _AgendaTaskCardState extends State<AgendaTaskCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _checkScale;

  bool _completing = false;
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _checkScale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    if (_completing) return;
    setState(() => _completing = true);
    _ctrl.forward();

    // Fire the write at 680ms regardless of mounted state — the DB write must
    // not be blocked by whether the card is still in the tree (e.g. user
    // navigates away mid-animation).
    await Future.delayed(const Duration(milliseconds: 680));
    HapticFeedback.mediumImpact();
    widget.onQuickComplete();

    if (!mounted) return;
    setState(() => _collapsed = true);
  }

  @override
  Widget build(BuildContext context) {
    final categoryStyle = _categoryStyle(widget.task.category.toLowerCase());
    final stripeColor = _stripeColor(widget.task);
    final isOverdue = widget.task.status == TaskStatus.overdue ||
        widget.task.dueDate.toLocal().isBefore(DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ));

    return ClipRect(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        child: _collapsed
            ? const SizedBox.shrink()
            : GestureDetector(
                onTap: () =>
                    context.push('/maintenance/${widget.task.id}'),
                child: AnimatedOpacity(
                  opacity: _completing ? 0.5 : 1.0,
                  duration: const Duration(milliseconds: 260),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? const Color(0x0EC9A84C)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOverdue
                            ? const Color(0x30C9A84C)
                            : AppColors.border,
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D2A2420),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Priority stripe ───────────────────────────
                          Container(width: 4, color: stripeColor),
                          // ── Category icon ─────────────────────────────
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(12, 13, 0, 13),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: categoryStyle.bgColor,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                categoryStyle.icon,
                                size: 18,
                                color: categoryStyle.iconColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // ── Task info ─────────────────────────────────
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.task.name,
                                    style: AppTextStyles.bodyMediumSemibold
                                        .copyWith(
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                      decoration: _completing
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: AppColors.textSecondary,
                                      decorationThickness: 1.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          widget.task.category,
                                          style: AppTextStyles.monoLabel
                                              .copyWith(
                                            color: AppColors.textTertiary,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _DiyProBadge(
                                          diyOrPro: widget.task.diyOrPro),
                                      if (widget.task.estimatedMinutes !=
                                          null) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '~${widget.task.estimatedMinutes}min',
                                          style: AppTextStyles.monoLabel
                                              .copyWith(
                                            color: AppColors.textTertiary,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (widget.showDate) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      DateFormat('MMM d').format(
                                          widget.task.dueDate.toLocal()),
                                      style: AppTextStyles.monoLabel.copyWith(
                                        color: AppColors.textTertiary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          // ── Quick-complete ────────────────────────────
                          GestureDetector(
                            onTap: _handleComplete,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14),
                              child: Center(
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 240),
                                  curve: Curves.easeOut,
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _completing
                                        ? _kSuccessGreen
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _completing
                                          ? _kSuccessGreen
                                          : AppColors.border,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: ScaleTransition(
                                      scale: _checkScale,
                                      child: const Icon(
                                        Icons.check_rounded,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  static Color _stripeColor(MaintenanceTask task) {
    if (task.status == TaskStatus.overdue) return AppColors.accent;
    return switch (task.priority) {
      TaskPriority.critical => AppColors.accent,
      TaskPriority.high => AppColors.sand,
      TaskPriority.medium => AppColors.slate,
      TaskPriority.low => AppColors.border,
    };
  }

  static _CategoryStyle _categoryStyle(String cat) {
    if (cat == 'hvac' || cat == 'heating' || cat == 'cooling') {
      return const _CategoryStyle(
        icon: Icons.air,
        iconColor: AppColors.slate,
        bgColor: AppColors.slateDim,
      );
    } else if (cat == 'plumbing' || cat == 'water') {
      return const _CategoryStyle(
        icon: Icons.water_drop_outlined,
        iconColor: AppColors.teal,
        bgColor: AppColors.tealDim,
      );
    } else if (cat == 'electrical') {
      return const _CategoryStyle(
        icon: Icons.bolt_outlined,
        iconColor: AppColors.sand,
        bgColor: AppColors.sandDim,
      );
    } else if (cat == 'safety' || cat == 'security') {
      return const _CategoryStyle(
        icon: Icons.security_outlined,
        iconColor: AppColors.sandAmber,
        bgColor: AppColors.sandDim,
      );
    } else if (cat == 'exterior' ||
        cat == 'roofing' ||
        cat == 'landscaping') {
      return const _CategoryStyle(
        icon: Icons.park_outlined,
        iconColor: AppColors.olive,
        bgColor: AppColors.oliveDim,
      );
    } else if (cat == 'interior' ||
        cat == 'kitchen' ||
        cat == 'bathroom') {
      return const _CategoryStyle(
        icon: Icons.home_outlined,
        iconColor: AppColors.plum,
        bgColor: AppColors.plumDim,
      );
    }
    return const _CategoryStyle(
      icon: Icons.build_outlined,
      iconColor: AppColors.textSecondary,
      bgColor: AppColors.warmFill,
    );
  }
}

// ── Category style record ──────────────────────────────────────────────────────

class _CategoryStyle {
  const _CategoryStyle({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
}

// ── DIY/PRO badge ──────────────────────────────────────────────────────────────

class _DiyProBadge extends StatelessWidget {
  const _DiyProBadge({required this.diyOrPro});

  final DiyOrPro diyOrPro;

  @override
  Widget build(BuildContext context) {
    final isPro = diyOrPro == DiyOrPro.professional;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isPro ? AppColors.slateDim : AppColors.oliveDim,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isPro ? 'PRO' : 'DIY',
        style: GoogleFonts.ibmPlexMono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isPro ? AppColors.slate : AppColors.olive,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
