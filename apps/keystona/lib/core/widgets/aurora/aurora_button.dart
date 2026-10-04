import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_radius.dart';

/// Coral pill — primary brand CTA.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  /// When true, button fills available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AuroraColors.coral,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AuroraColors.coralDim,
        disabledForegroundColor: AuroraColors.coral,
        elevation: 0,
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.full),
        minimumSize: expand ? const Size(double.infinity, 48) : const Size(0, 48),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Text(label),
    );
    return btn;
  }
}

/// White + inkBorderStrong outline — secondary CTA.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AuroraColors.ink,
        side: const BorderSide(color: AuroraColors.inkBorderStrong, width: 1.5),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11.5),
        shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.full),
        minimumSize: expand ? const Size(double.infinity, 48) : const Size(0, 48),
      ),
      child: Text(label),
    );
  }
}

/// Cobalt pill — save / confirm CTA.
class SaveButton extends StatelessWidget {
  const SaveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AuroraColors.cobalt,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AuroraColors.cobaltDim,
        disabledForegroundColor: AuroraColors.cobalt,
        elevation: 0,
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.full),
        minimumSize: expand ? const Size(double.infinity, 48) : const Size(0, 48),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Text(label),
    );
  }
}

/// Transparent text — inline secondary action ("View all", "Edit", "Cancel").
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AuroraColors.coral,
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.md),
      ),
      child: Text(label),
    );
  }
}
