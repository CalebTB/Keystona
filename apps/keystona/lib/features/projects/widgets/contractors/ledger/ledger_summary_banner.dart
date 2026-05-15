import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../models/project_contractor.dart';

/// Deep-navy summary banner showing aggregate payment data for the team.
///
/// Left: total paid to date + outstanding sub-label.
/// Right: total vendor count.
class LedgerSummaryBanner extends StatelessWidget {
  const LedgerSummaryBanner({
    super.key,
    required this.contractors,
  });

  final List<ProjectContractor> contractors;

  double get _totalPaid => contractors.fold(
        0.0,
        (sum, c) => sum + (c.amountPaid ?? 0.0),
      );

  double get _totalOutstanding => contractors.fold(0.0, (sum, c) {
        final contract = c.contractAmount ?? 0.0;
        final paid = c.amountPaid ?? 0.0;
        return sum + (contract - paid).clamp(0.0, double.infinity);
      });

  String _fmtCompact(double v) {
    if (v >= 10000) return '\$${(v / 1000).toStringAsFixed(0)}k';
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
    return '\$${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final paid = _totalPaid;
    final outstanding = _totalOutstanding;
    final fullyPaid = outstanding <= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSizes.md, AppSizes.md, AppSizes.md, 0,
      ),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: paid + outstanding.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAID TO DATE',
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: Color(0x80FFFFFF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmtCompact(paid),
                  style: GoogleFonts.fraunces(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                if (fullyPaid)
                  Text(
                    'Fully paid',
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 11,
                      color: Color(0x80FFFFFF),
                    ),
                  )
                else
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                        color: Color(0x80FFFFFF),
                      ),
                      children: [
                        TextSpan(
                          text: _fmtCompact(outstanding),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: ' outstanding'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Right: vendor count.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${contractors.length}',
                style: GoogleFonts.fraunces(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                'VENDORS',
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0x80FFFFFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
