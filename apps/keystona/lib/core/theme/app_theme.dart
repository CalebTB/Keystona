import 'package:flutter/material.dart';

import 'aurora_colors.dart';
import 'aurora_radius.dart';
import 'aurora_sizes.dart';
import 'aurora_spacing.dart';
import 'aurora_typography.dart';

/// Keystona Material 3 theme — Aurora kit.
///
/// Built only from Aurora tokens. Aurora widgets in `core/widgets/aurora/`
/// style themselves; this theme is the baseline for stock Material widgets
/// that screens still use. Cobalt is the action color, coral only means
/// "act now"/error, and there are no tinted container fills.
///
/// Wire in [MaterialApp.theme] via [AppTheme.light].
abstract final class AppTheme {
  static const WidgetStateProperty<Color?> _noOutline =
      WidgetStatePropertyAll<Color?>(AuroraColors.paper);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // ─── Canvas ─────────────────────────────────────────────────────────────
      scaffoldBackgroundColor: AuroraColors.paper,
      canvasColor: AuroraColors.paper,
      // Aurora has no Material ripple.
      splashFactory: NoSplash.splashFactory,
      highlightColor: AuroraColors.inkDisabledFill,

      // ─── Color Scheme ────────────────────────────────────────────────────────
      colorScheme: const ColorScheme.light(
        primary: AuroraColors.cobalt,
        onPrimary: AuroraColors.paper,
        primaryContainer: AuroraColors.paper,
        onPrimaryContainer: AuroraColors.ink,
        secondary: AuroraColors.ink,
        onSecondary: AuroraColors.paper,
        secondaryContainer: AuroraColors.paper,
        onSecondaryContainer: AuroraColors.ink,
        tertiary: AuroraColors.lime,
        onTertiary: AuroraColors.oliveDeep,
        tertiaryContainer: AuroraColors.lime,
        onTertiaryContainer: AuroraColors.oliveDeep,
        error: AuroraColors.coral,
        onError: AuroraColors.paper,
        errorContainer: AuroraColors.paper,
        onErrorContainer: AuroraColors.coralDeep,
        surface: AuroraColors.paper,
        onSurface: AuroraColors.ink,
        surfaceContainerHighest: AuroraColors.inkDisabledFill,
        onSurfaceVariant: AuroraColors.inkSecondary,
        outline: AuroraColors.inkBorder,
        outlineVariant: AuroraColors.inkBorderStrong,
        shadow: AuroraColors.ink,
        scrim: AuroraColors.scrim,
        inverseSurface: AuroraColors.ink,
        onInverseSurface: AuroraColors.paper,
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
        surfaceTintColor: AuroraColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AuroraType.sheetTitle,
        iconTheme: const IconThemeData(
          color: AuroraColors.ink,
          size: AuroraIconSizes.xl,
        ),
        actionsIconTheme: const IconThemeData(
          color: AuroraColors.ink,
          size: AuroraIconSizes.xl,
        ),
      ),

      // ─── Bottom Navigation Bar ────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AuroraColors.paper,
        selectedItemColor: AuroraColors.ink,
        unselectedItemColor: AuroraColors.inkPlaceholder,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AuroraType.tabLabel.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AuroraType.tabLabel,
      ),

      // ─── Navigation Bar (Material 3) ──────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AuroraColors.paper,
        surfaceTintColor: AuroraColors.paper,
        indicatorColor: AuroraColors.paper,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? AuroraColors.ink
              : AuroraColors.inkPlaceholder;
          return IconThemeData(color: color, size: AuroraIconSizes.xl);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AuroraType.tabLabel.copyWith(
              color: AuroraColors.ink,
              fontWeight: FontWeight.w700,
            );
          }
          return AuroraType.tabLabel;
        }),
        elevation: 0,
      ),

      // ─── Elevated Button (primary pill) ──────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AuroraColors.cobalt,
          foregroundColor: AuroraColors.paper,
          disabledBackgroundColor: AuroraColors.inkDisabledFill,
          disabledForegroundColor: AuroraColors.inkPlaceholder,
          textStyle: AuroraType.button,
          minimumSize: const Size(double.infinity, AuroraSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSpacing.pillH,
            vertical: AuroraSpacing.space5,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.full),
          elevation: 0,
        ),
      ),

      // ─── Filled Button ────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AuroraColors.cobalt,
          foregroundColor: AuroraColors.paper,
          disabledBackgroundColor: AuroraColors.inkDisabledFill,
          disabledForegroundColor: AuroraColors.inkPlaceholder,
          textStyle: AuroraType.button,
          minimumSize: const Size(double.infinity, AuroraSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSpacing.pillH,
            vertical: AuroraSpacing.space5,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.full),
          elevation: 0,
        ),
      ),

      // ─── Outlined Button (secondary pill) ─────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AuroraColors.ink,
          disabledForegroundColor: AuroraColors.inkPlaceholder,
          textStyle: AuroraType.button,
          minimumSize: const Size(double.infinity, AuroraSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSpacing.pillH,
            vertical: AuroraSpacing.space5,
          ),
          side: const BorderSide(
            color: AuroraColors.inkBorderStrong,
            width: AuroraBorders.emphasis,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.full),
        ),
      ),

      // ─── Text Button ─────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AuroraColors.cobalt,
          disabledForegroundColor: AuroraColors.inkPlaceholder,
          textStyle: AuroraType.buttonSm,
          minimumSize: const Size(AuroraSizes.minTouch, AuroraSizes.minTouch),
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSpacing.space5,
            vertical: AuroraSpacing.space3,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.md),
        ),
      ),

      // ─── Card ─────────────────────────────────────────────────────────────────
      cardTheme: const CardThemeData(
        color: AuroraColors.paper,
        surfaceTintColor: AuroraColors.paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AuroraRadius.xl,
          side: BorderSide(
            color: AuroraColors.inkBorder,
            width: AuroraBorders.regular,
          ),
        ),
      ),

      // ─── Input Decoration ─────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AuroraColors.paper,
        labelStyle: AuroraType.label,
        hintStyle: AuroraType.input.copyWith(color: AuroraColors.inkPlaceholder),
        floatingLabelStyle: AuroraType.label.copyWith(color: AuroraColors.cobalt),
        helperStyle: AuroraType.helper,
        errorStyle: AuroraType.helper.copyWith(color: AuroraColors.coral),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.space6,
          vertical: AuroraSpacing.space5,
        ),
        border: const OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: BorderSide(
            color: AuroraColors.inkInputBorder,
            width: AuroraBorders.regular,
          ),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: BorderSide(
            color: AuroraColors.inkInputBorder,
            width: AuroraBorders.regular,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: BorderSide(
            color: AuroraColors.cobalt,
            width: AuroraBorders.emphasis,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: BorderSide(
            color: AuroraColors.coral,
            width: AuroraBorders.regular,
          ),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: BorderSide(
            color: AuroraColors.coral,
            width: AuroraBorders.emphasis,
          ),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: BorderSide(
            color: AuroraColors.inkBorder,
            width: AuroraBorders.regular,
          ),
        ),
      ),

      // ─── Divider ─────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AuroraColors.inkBorder,
        thickness: AuroraBorders.hairline,
        space: AuroraBorders.hairline,
      ),

      // ─── Chip ─────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AuroraColors.paper,
        selectedColor: AuroraColors.ink,
        disabledColor: AuroraColors.inkDisabledFill,
        surfaceTintColor: AuroraColors.paper,
        checkmarkColor: AuroraColors.paper,
        labelStyle: AuroraType.chip,
        secondaryLabelStyle: AuroraType.chip.copyWith(color: AuroraColors.paper),
        padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.space2),
        shape: const RoundedRectangleBorder(
          borderRadius: AuroraRadius.full,
          side: BorderSide(
            color: AuroraColors.inkInputBorder,
            width: AuroraBorders.regular,
          ),
        ),
        elevation: 0,
        pressElevation: 0,
      ),

      // ─── List Tile ────────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: AuroraColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.screenPadH,
          vertical: AuroraSpacing.space1,
        ),
        titleTextStyle: AuroraType.body,
        subtitleTextStyle: AuroraType.bodySm.copyWith(
          color: AuroraColors.inkSecondary,
        ),
        iconColor: AuroraColors.ink,
        minLeadingWidth: AuroraIconSizes.xl,
        shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.lg),
      ),

      // ─── Icon ─────────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AuroraColors.ink,
        size: AuroraIconSizes.xl,
      ),

      // ─── Snack Bar ────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AuroraColors.ink,
        contentTextStyle: AuroraType.body.copyWith(color: AuroraColors.paper),
        actionTextColor: AuroraColors.lime,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.lg),
        elevation: 0,
      ),

      // ─── Dialog ───────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AuroraColors.paper,
        surfaceTintColor: AuroraColors.paper,
        elevation: 0,
        titleTextStyle: AuroraType.h2,
        contentTextStyle: AuroraType.body,
        shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.modal),
      ),

      // ─── Bottom Sheet ─────────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AuroraColors.paper,
        surfaceTintColor: AuroraColors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AuroraRadius.sheetTop),
        modalBackgroundColor: AuroraColors.paper,
        modalBarrierColor: AuroraColors.scrim,
        modalElevation: 0,
      ),

      // ─── Progress Indicator ───────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AuroraColors.cobalt,
        linearTrackColor: AuroraColors.inkDisabledFill,
        circularTrackColor: AuroraColors.inkDisabledFill,
      ),

      // ─── Switch ───────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll<Color?>(AuroraColors.paper),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AuroraColors.cobalt;
          return AuroraColors.inkTrackOff;
        }),
        trackOutlineColor: _noOutline,
        trackOutlineWidth: const WidgetStatePropertyAll<double?>(0),
      ),

      // ─── Checkbox ─────────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AuroraColors.cobalt;
          return AuroraColors.paper;
        }),
        checkColor: const WidgetStatePropertyAll<Color?>(AuroraColors.paper),
        side: const BorderSide(
          color: AuroraColors.inkInputBorder,
          width: AuroraBorders.emphasis,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.xs),
      ),

      // ─── Tab Bar ──────────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AuroraColors.ink,
        unselectedLabelColor: AuroraColors.inkPlaceholder,
        labelStyle: AuroraType.tabLabel.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AuroraType.tabLabel,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AuroraColors.ink,
            width: AuroraBorders.indicator,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AuroraColors.inkBorder,
      ),

      // ─── FAB ──────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AuroraColors.cobalt,
        foregroundColor: AuroraColors.paper,
        elevation: 0,
        shape: CircleBorder(),
      ),
    );
  }
}
