import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme_constants.dart';

/// Application theme configuration
class AppTheme {
  /// Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryDark,
        tertiary: AppColors.accent,
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkOnSurface,
        onBackground: AppColors.darkOnBackground,
        onError: Colors.white,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.darkBackground,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkOnSurface,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.primaryFont,
          fontSize: AppTypography.lg,
          fontWeight: AppTypography.semiBold,
          color: AppColors.darkOnSurface,
        ),
        iconTheme: IconThemeData(
          color: AppColors.darkOnSurface,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: AppElevation.sm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        color: AppColors.darkSurface,
        surfaceTintColor: AppColors.primaryLight,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppElevation.sm,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTypography.primaryFont,
            fontSize: AppTypography.base,
            fontWeight: AppTypography.semiBold,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTypography.primaryFont,
            fontSize: AppTypography.base,
            fontWeight: AppTypography.semiBold,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTypography.primaryFont,
            fontSize: AppTypography.base,
            fontWeight: AppTypography.medium,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.darkOnSurface,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppColors.grey700, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        elevation: AppElevation.lg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        backgroundColor: AppColors.darkSurface,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: AppElevation.lg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        backgroundColor: AppColors.darkSurface,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.grey700,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.darkOnSurface,
        size: 24,
      ),

      // Text Theme
      textTheme: _buildTextTheme(Brightness.dark),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: AppElevation.md,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkSurfaceVariant,
        contentTextStyle: const TextStyle(
          fontFamily: AppTypography.primaryFont,
          fontSize: AppTypography.base,
          color: AppColors.darkOnSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.grey800,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        textStyle: const TextStyle(
          fontFamily: AppTypography.primaryFont,
          fontSize: AppTypography.sm,
          color: Colors.white,
        ),
        waitDuration: const Duration(milliseconds: 500),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.grey700,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return AppColors.grey400;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.grey600;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return AppColors.grey400;
        }),
      ),

      // Slider Theme
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.grey600,
        thumbColor: AppColors.primary,
        overlayColor: Color(0x403B82F6),
      ),
    );
  }

  /// Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryLight,
        tertiary: AppColors.accent,
        surface: AppColors.lightSurface,
        background: AppColors.lightBackground,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightOnSurface,
        onBackground: AppColors.lightOnBackground,
        onError: Colors.white,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.lightBackground,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightOnSurface,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.primaryFont,
          fontSize: AppTypography.lg,
          fontWeight: AppTypography.semiBold,
          color: AppColors.lightOnSurface,
        ),
        iconTheme: IconThemeData(
          color: AppColors.lightOnSurface,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: AppElevation.sm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        color: AppColors.lightSurface,
        surfaceTintColor: AppColors.primaryLight,
      ),

      // Similar configurations for other components...
      // (Abbreviated for brevity - follows same pattern as dark theme)

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppElevation.sm,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppColors.grey300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),

      textTheme: _buildTextTheme(Brightness.light),

      dividerTheme: const DividerThemeData(
        color: AppColors.grey200,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Build text theme
  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.dark
        ? AppColors.darkOnSurface
        : AppColors.lightOnSurface;

    return TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontFamily: AppTypography.primaryFont,
        fontSize: AppTypography.huge,
        fontWeight: AppTypography.bold,
        color: baseColor,
        height: AppTypography.lineHeightTight,
      ),
      displayMedium: TextStyle(
        fontFamily: AppTypography.primaryFont,
        fontSize: AppTypography.xxxl,
        fontWeight: AppTypography.bold,
        color: baseColor,
        height: AppTypography.lineHeightTight,
      ),
      displaySmall: TextStyle(
        fontFamily: AppTypography.primaryFont,
        fontSize: AppTypography.xxl,
        fontWeight: AppTypography.semiBold,
        color: baseColor,
        height: AppTypography.lineHeightNormal,
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontFamily: AppTypography.primaryFont,
        fontSize: AppTypography.xl,
        fontWeight: AppTypography.semiBold,
        color: baseColor,
        height: AppTypography.lineHeightNormal,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppTypography.primaryFont,
        fontSize: AppTypography.lg,
        fontWeight: AppTypography.semiBold,
        color: baseColor,
        height: AppTypography.lineHeightNormal,
      ),
      headlineSmall: TextStyle(
        fontFamily: AppTypography.primaryFont,
        fontSize: AppTypography.md,
        fontWeight: AppTypography.medium,
        color: baseColor,
        height: AppTypography.lineHeightNormal,
      ),

      // Title styles
      titleLarge: TextStyle(
        fontFamily: AppTypography.primaryFont,
        fontSize: AppTypography.md,
        fontWeight: AppTypography.medium,
        color: baseColor,
        height: AppTypography.lineHeightNormal,
      ),
      titleMedium: TextStyle(
        fontFamily: AppTypography.primaryFont,
        fontSize: AppTypography.base,
        fontWeight: AppTypography.medium,
        color: baseColor,
        height: AppTypography.lineHeightNormal,
      ),
      titleSmall: TextStyle(
        fontFamily: AppTypography.primaryFont,
        fontSize: AppTypography.sm,
        fontWeight: AppTypography.medium,
        color: baseColor,
        height: AppTypography.lineHeightNormal,
      ),

      // Body styles
      bodyLarge: TextStyle(
        fontFamily: AppTypography.primaryFont,
        fontSize: AppTypography.md,
        fontWeight: AppTypography.regular,
        color: baseColor,
        height: AppTypography.lineHeightNormal,
      ),
      bodyMedium: TextStyle(
        fontFamily: AppTypography.primaryFont,
        fontSize: AppTypography.base,
        fontWeight: AppTypography.regular,
        color: baseColor,
        height: AppTypography.lineHeightNormal,
      ),
      bodySmall: TextStyle(
        fontFamily: AppTypography.primaryFont,
        fontSize: AppTypography.sm,
        fontWeight: AppTypography.regular,
        color: baseColor,
        height: AppTypography.lineHeightNormal,
      ),

      // Label styles
      labelLarge: TextStyle(
        fontFamily: AppTypography.primaryFont,
        fontSize: AppTypography.base,
        fontWeight: AppTypography.medium,
        color: baseColor,
      ),
      labelMedium: TextStyle(
        fontFamily: AppTypography.primaryFont,
        fontSize: AppTypography.sm,
        fontWeight: AppTypography.medium,
        color: baseColor,
      ),
      labelSmall: TextStyle(
        fontFamily: AppTypography.primaryFont,
        fontSize: AppTypography.xs,
        fontWeight: AppTypography.medium,
        color: baseColor,
      ),
    );
  }
}
