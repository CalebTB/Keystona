import 'package:flutter/material.dart';
import '../../../../../core/theme/aurora_typography.dart';
import '../../../../../core/theme/aurora_colors.dart';


/// 44px circular avatar for a contractor, using role color as background.
///
/// Shows white Inter initials extracted from [name] (max 2 words).
class ContractorAvatar extends StatelessWidget {
  const ContractorAvatar({
    super.key,
    required this.name,
    required this.roleColor,
    this.size = 44,
  });

  final String name;
  final Color roleColor;
  final double size;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).take(2);
    return parts
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: roleColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials.isEmpty ? '?' : _initials,
        style: AuroraType.h1.copyWith(fontSize: size * 0.32, color: AuroraColors.paper, height: 1),
      ),
    );
  }
}
