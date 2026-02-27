import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_sizes.dart';
import 'app_text_styles.dart';

/// Keystona Material 3 theme.
///
/// Wire in [MaterialApp.theme] via [AppTheme.light].
///
/// Rules:
/// - No hardcoded hex values — always reference [AppColors].
/// - No inline TextStyle definitions — always reference [AppTextStyles].
/// - No raw numeric sizes — always reference [AppSizes].
abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,

      // ─── Color Scheme ──────────────────────────────────────────────────────
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.deepNavy,
        onPrimary: AppColors.textInverse,
        primaryContainer: AppColors.infoLight,
        onPrimaryContainer: AppColors.deepNavy,
        secondary: AppColors.goldAccent,
        onSecondary: AppColors.textInverse,
        secondaryContainer: AppColors.warningLight,
        onSecondaryContainer: AppColors.gray900,
        tertiary: AppColors.success,
        onTertiary: AppColors.textInverse,
        tertiaryContainer: AppColors.successLight,
        onTertiaryContainer: AppColors.gray900,
        error: AppColors.error,
        onError: AppColors.textInverse,
        errorContainer: AppColors.errorLight,
        onErrorContainer: AppColors.error,
        surface: AppColors.warmOffWhite,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.divider,
        shadow: AppColors.gray900,
        scrim: AppColors.gray900,
        inverseSurface: AppColors.gray900,
        onInverseSurface: AppColors.textInverse,
        inversePrimary: AppColors.goldAccent,
      ),

      // ─── Scaffold ──────────────────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.warmOffWhite,

      // ─── Text Theme ────────────────────────────────────────────────────────
      // Maps Keystona named styles to Material text theme roles.
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.h1,
        headlineLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        headlineSmall: AppTextStyles.h3,
        titleLarge: AppTextStyles.h3,
        titleMedium: AppTextStyles.h4,
        titleSmall: AppTextStyles.bodyLargeSemibold,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),

      // ─── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.warmOffWhite,
        foregroundColor: AppColors.deepNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h2.copyWith(color: AppColors.deepNavy),
        iconTheme: const IconThemeData(
          color: AppColors.deepNavy,
          size: AppSizes.iconMd,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.deepNavy,
          size: AppSizes.iconMd,
        ),
      ),

      // ─── Bottom Navigation Bar ─────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.deepNavy,
        unselectedItemColor: AppColors.gray400,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ─── Navigation Bar (Material 3) ───────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.deepNavy.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.deepNavy,
              size: AppSizes.iconMd,
            );
          }
          return const IconThemeData(
            color: AppColors.gray400,
            size: AppSizes.iconMd,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall
                .copyWith(color: AppColors.deepNavy);
          }
          return AppTextStyles.labelSmall.copyWith(color: AppColors.gray400);
        }),
        elevation: 0,
      ),

      // ─── Elevated Button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepNavy,
          foregroundColor: AppColors.textInverse,
          disabledBackgroundColor: AppColors.gray300,
          disabledForegroundColor: AppColors.textDisabled,
          textStyle: AppTextStyles.button.copyWith(color: AppColors.textInverse),
          minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
          padding: AppPadding.button,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.sm,
          ),
          elevation: 0,
        ),
      ),

      // ─── Outlined Button ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepNavy,
          disabledForegroundColor: AppColors.textDisabled,
          textStyle: AppTextStyles.button.copyWith(color: AppColors.deepNavy),
          minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
          padding: AppPadding.button,
          side: const BorderSide(color: AppColors.deepNavy, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.sm,
          ),
        ),
      ),

      // ─── Text Button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.deepNavy,
          disabledForegroundColor: AppColors.textDisabled,
          textStyle: AppTextStyles.button.copyWith(color: AppColors.deepNavy),
          padding: AppPadding.button,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.sm,
          ),
        ),
      ),

      // ─── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Input Decoration ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray50,
        labelStyle: AppTextStyles.labelLarge,
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
        floatingLabelStyle:
            AppTextStyles.labelMedium.copyWith(color: AppColors.deepNavy),
        errorStyle:
            AppTextStyles.caption.copyWith(color: AppColors.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.gray300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.gray300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.deepNavy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.gray200, width: 1),
        ),
      ),

      // ─── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ─── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.gray100,
        selectedColor: AppColors.deepNavy.withValues(alpha: 0.12),
        disabledColor: AppColors.gray200,
        labelStyle: AppTextStyles.labelMedium,
        secondaryLabelStyle:
            AppTextStyles.labelMedium.copyWith(color: AppColors.deepNavy),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm + AppSizes.xs, // 12px
          vertical: AppSizes.sm - 2,              // 6px
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.sm,
          side: BorderSide.none,
        ),
        elevation: 0,
        pressElevation: 0,
      ),

      // ─── List Tile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.xs,
        ),
        titleTextStyle: AppTextStyles.bodyMedium,
        subtitleTextStyle:
            AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        iconColor: AppColors.deepNavy,
        minLeadingWidth: AppSizes.iconMd,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
        ),
      ),

      // ─── Icon ──────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.deepNavy,
        size: AppSizes.iconMd,
      ),

      // ─── Snack Bar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.gray900,
        contentTextStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textInverse),
        actionTextColor: AppColors.goldAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
        elevation: 4,
      ),

      // ─── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleTextStyle: AppTextStyles.h3,
        contentTextStyle: AppTextStyles.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
      ),

      // ─── Bottom Sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSizes.radiusXl),
            topRight: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        modalBackgroundColor: AppColors.surface,
        modalElevation: 0,
      ),

      // ─── Progress Indicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.deepNavy,
        linearTrackColor: AppColors.gray200,
        circularTrackColor: AppColors.gray200,
      ),

      // ─── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.surface;
          }
          return AppColors.gray400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.deepNavy;
          }
          return AppColors.gray300;
        }),
      ),

      // ─── Checkbox ──────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.deepNavy;
          }
          return AppColors.surface;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textInverse),
        side: const BorderSide(color: AppColors.gray400, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm / 2),
        ),
      ),

      // ─── Tab Bar ───────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.deepNavy,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.labelLarge
            .copyWith(color: AppColors.deepNavy),
        unselectedLabelStyle: AppTextStyles.labelLarge
            .copyWith(color: AppColors.textSecondary),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.goldAccent, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.divider,
      ),
    );
  }
}
