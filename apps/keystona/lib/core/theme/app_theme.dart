import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'aurora_colors.dart';
import 'aurora_radius.dart';
import 'aurora_typography.dart';

/// Keystona Material 3 theme — Aurora Design System v2.0.
///
/// Wire in [MaterialApp.theme] via [AppTheme.light].
abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // ─── Canvas ─────────────────────────────────────────────────────────────
      scaffoldBackgroundColor: AuroraColors.paper,
      canvasColor: AuroraColors.paper,

      // ─── Color Scheme ────────────────────────────────────────────────────────
      colorScheme: const ColorScheme.light(
        primary: AuroraColors.coral,
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: AuroraColors.coralDim,
        onPrimaryContainer: AuroraColors.coralDeep,
        secondary: AuroraColors.cobalt,
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: AuroraColors.cobaltDim,
        onSecondaryContainer: AuroraColors.cobaltDeep,
        tertiary: AuroraColors.lime,
        onTertiary: AuroraColors.ink,
        tertiaryContainer: AuroraColors.limeDim,
        onTertiaryContainer: AuroraColors.limeDeep,
        error: AuroraColors.coral,
        onError: Color(0xFFFFFFFF),
        errorContainer: AuroraColors.coralDim,
        onErrorContainer: AuroraColors.coralDeep,
        surface: AuroraColors.paper,
        onSurface: AuroraColors.ink,
        surfaceContainerHighest: AuroraColors.butter,
        onSurfaceVariant: AuroraColors.inkSecondary,
        outline: AuroraColors.inkBorder,
        outlineVariant: AuroraColors.inkBorderStrong,
        shadow: AuroraColors.ink,
        scrim: AuroraColors.ink,
        inverseSurface: AuroraColors.ink,
        onInverseSurface: Color(0xFFFFFFFF),
        inversePrimary: AuroraColors.lime,
      ),

      // ─── Page Transitions ────────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),

      // ─── Text Theme ──────────────────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: AuroraType.displayXl,
        displayMedium: AuroraType.displayLg,
        displaySmall: AuroraType.h1,
        headlineLarge: AuroraType.h1,
        headlineMedium: AuroraType.h2,
        headlineSmall: AuroraType.h3,
        titleLarge: AuroraType.h3,
        titleMedium: AuroraType.bodyLg,
        titleSmall: AuroraType.body,
        bodyLarge: AuroraType.bodyLg,
        bodyMedium: AuroraType.body,
        bodySmall: AuroraType.bodySm,
        labelLarge: AuroraType.label,
        labelMedium: AuroraType.label,
        labelSmall: AuroraType.labelSm,
      ),

      // ─── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AuroraColors.paper,
        foregroundColor: AuroraColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AuroraType.h2.copyWith(color: AuroraColors.ink),
        iconTheme: const IconThemeData(color: AuroraColors.ink, size: 24),
        actionsIconTheme: const IconThemeData(color: AuroraColors.ink, size: 24),
      ),

      // ─── Bottom Navigation Bar ────────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AuroraColors.paper,
        selectedItemColor: AuroraColors.coral,
        unselectedItemColor: AuroraColors.inkTertiary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),

      // ─── Navigation Bar (Material 3) ──────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AuroraColors.paper,
        indicatorColor: AuroraColors.coralDim,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AuroraColors.coral, size: 24);
          }
          return const IconThemeData(color: AuroraColors.inkTertiary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AuroraColors.coral,
            );
          }
          return const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AuroraColors.inkTertiary,
          );
        }),
        elevation: 0,
      ),

      // ─── Elevated Button ──────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AuroraColors.coral,
          foregroundColor: const Color(0xFFFFFFFF),
          disabledBackgroundColor: AuroraColors.coralDim,
          disabledForegroundColor: AuroraColors.coral,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.full),
          elevation: 0,
        ),
      ),

      // ─── Filled Button ────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AuroraColors.cobalt,
          foregroundColor: const Color(0xFFFFFFFF),
          disabledBackgroundColor: AuroraColors.cobaltDim,
          disabledForegroundColor: AuroraColors.cobalt,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.full),
          elevation: 0,
        ),
      ),

      // ─── Outlined Button ──────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AuroraColors.ink,
          disabledForegroundColor: AuroraColors.inkTertiary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11.5),
          side: const BorderSide(color: AuroraColors.inkBorderStrong, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.full),
        ),
      ),

      // ─── Text Button ─────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AuroraColors.coral,
          disabledForegroundColor: AuroraColors.inkTertiary,
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.md),
        ),
      ),

      // ─── Card ─────────────────────────────────────────────────────────────────
      cardTheme: const CardThemeData(
        color: AuroraColors.paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AuroraRadius.xl,
          side: BorderSide(color: AuroraColors.inkBorder, width: 1),
        ),
      ),

      // ─── Input Decoration ─────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AuroraColors.paper,
        labelStyle: AuroraType.label,
        hintStyle: AuroraType.body.copyWith(color: AuroraColors.inkTertiary),
        floatingLabelStyle: AuroraType.label.copyWith(color: AuroraColors.coral),
        errorStyle: AuroraType.bodySm.copyWith(color: AuroraColors.coral),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: BorderSide(color: AuroraColors.inkBorder, width: 1.5),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: BorderSide(color: AuroraColors.inkBorder, width: 1.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: BorderSide(color: AuroraColors.coral, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: BorderSide(color: AuroraColors.coral, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: BorderSide(color: AuroraColors.coral, width: 2),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: BorderSide(color: AuroraColors.inkBorder, width: 1),
        ),
      ),

      // ─── Divider ─────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AuroraColors.inkBorder,
        thickness: 0.5,
        space: 0,
      ),

      // ─── Chip ─────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AuroraColors.paper,
        selectedColor: AuroraColors.ink,
        disabledColor: AuroraColors.butter,
        labelStyle: AuroraType.body.copyWith(fontWeight: FontWeight.w500),
        secondaryLabelStyle: AuroraType.body.copyWith(
          fontWeight: FontWeight.w500,
          color: const Color(0xFFFFFFFF),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        shape: const RoundedRectangleBorder(
          borderRadius: AuroraRadius.full,
          side: BorderSide(color: AuroraColors.inkBorder, width: 1),
        ),
        elevation: 0,
        pressElevation: 0,
      ),

      // ─── List Tile ────────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: AuroraColors.paper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: AuroraType.body,
        subtitleTextStyle: AuroraType.bodySm.copyWith(
          color: AuroraColors.inkSecondary,
        ),
        iconColor: AuroraColors.ink,
        minLeadingWidth: 24,
        shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.lg),
      ),

      // ─── Icon ─────────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: AuroraColors.ink, size: 24),

      // ─── Snack Bar ────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AuroraColors.ink,
        contentTextStyle: AuroraType.body.copyWith(color: const Color(0xFFFFFFFF)),
        actionTextColor: AuroraColors.lime,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.md),
        elevation: 4,
      ),

      // ─── Dialog ───────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AuroraColors.paper,
        elevation: 0,
        titleTextStyle: AuroraType.h2,
        contentTextStyle: AuroraType.body,
        shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.xl),
      ),

      // ─── Bottom Sheet ─────────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AuroraColors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
        ),
        modalBackgroundColor: AuroraColors.paper,
        modalElevation: 0,
      ),

      // ─── Progress Indicator ───────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AuroraColors.coral,
        linearTrackColor: AuroraColors.butter,
        circularTrackColor: AuroraColors.butter,
      ),

      // ─── Switch ───────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFFFFFFF);
          }
          return AuroraColors.inkTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AuroraColors.coral;
          return AuroraColors.butter;
        }),
      ),

      // ─── Checkbox ─────────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AuroraColors.cobalt;
          return AuroraColors.paper;
        }),
        checkColor: WidgetStateProperty.all(const Color(0xFFFFFFFF)),
        side: const BorderSide(color: AuroraColors.inkBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ─── Tab Bar ──────────────────────────────────────────────────────────────
      tabBarTheme: const TabBarThemeData(
        labelColor: AuroraColors.coral,
        unselectedLabelColor: AuroraColors.inkTertiary,
        labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: AuroraColors.coral, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AuroraColors.inkBorder,
      ),

      // ─── FAB ──────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AuroraColors.coral,
        foregroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        shape: CircleBorder(),
      ),
    );
  }
}
