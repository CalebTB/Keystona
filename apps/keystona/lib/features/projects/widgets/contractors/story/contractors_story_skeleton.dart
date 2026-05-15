import 'package:flutter/material.dart';

/// Skeleton for [ContractorsStoryView].
///
/// Mimics the card-stack layout — dark olive card with shimmer bars where
/// the avatar, name, stats grid, and action bar sit. Displays on frame 1
/// so the user never sees a blank screen.
class ContractorsStorySkeleton extends StatefulWidget {
  const ContractorsStorySkeleton({super.key});

  @override
  State<ContractorsStorySkeleton> createState() =>
      _ContractorsStorySkeletonState();
}

class _ContractorsStorySkeletonState extends State<ContractorsStorySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final shimmer = Color.fromRGBO(255, 255, 255, _anim.value * 0.12);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3D5040),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Eyebrow shimmer
                _Bar(color: shimmer, width: 140, height: 10),
                const SizedBox(height: 8),
                // H1 shimmer
                _Bar(color: shimmer, width: 180, height: 28),
                const SizedBox(height: 32),

                // Avatar + name
                Row(
                  children: [
                    _Circle(color: shimmer, size: 64),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bar(color: shimmer, width: 140, height: 22),
                        const SizedBox(height: 8),
                        _Bar(color: shimmer, width: 100, height: 10),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quote block
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E3D30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bar(color: shimmer, width: double.infinity, height: 10),
                      const SizedBox(height: 6),
                      _Bar(color: shimmer, width: double.infinity, height: 10),
                      const SizedBox(height: 6),
                      _Bar(color: shimmer, width: 120, height: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stats 2×2
                Row(
                  children: [
                    Expanded(child: _StatCell(shimmer: shimmer)),
                    const SizedBox(width: 8),
                    Expanded(child: _StatCell(shimmer: shimmer)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _StatCell(shimmer: shimmer)),
                    const SizedBox(width: 8),
                    Expanded(child: _StatCell(shimmer: shimmer)),
                  ],
                ),
                const SizedBox(height: 20),

                // Projects together
                _Bar(color: shimmer, width: 120, height: 10),
                const SizedBox(height: 12),
                _Bar(color: shimmer, width: double.infinity, height: 16),

                const Spacer(),

                // Action bar
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E3D30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Bar(color: shimmer, width: 48, height: 10),
                      _Bar(color: shimmer, width: 48, height: 10),
                      _Bar(color: shimmer, width: 48, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.color,
    required this.width,
    required this.height,
  });

  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.shimmer});

  final Color shimmer;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF2E3D30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Bar(color: shimmer, width: 40, height: 8),
          const SizedBox(height: 6),
          _Bar(color: shimmer, width: 60, height: 14),
        ],
      ),
    );
  }
}
