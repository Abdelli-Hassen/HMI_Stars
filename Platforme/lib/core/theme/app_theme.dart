import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
        inversePrimary: AppColors.inversePrimary,
        surfaceTint: AppColors.surfaceTint,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceContainerLowest,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.titleMedium.copyWith(
          color: AppColors.primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.outline.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        labelStyle: AppTextStyles.labelMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: AppColors.onPrimary,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        selectedColor: AppColors.primaryFixed,
        labelStyle: AppTextStyles.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.outlineVariant.withValues(alpha: 0.15),
        thickness: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.surfaceContainerLow;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primaryFixed,
        onPrimary: AppColors.onPrimaryFixed,
        primaryContainer: AppColors.primary,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondaryFixedDim,
        onSecondary: AppColors.onSecondaryFixed,
        secondaryContainer: AppColors.secondary,
        onSecondaryContainer: AppColors.secondaryContainer,
        tertiary: AppColors.tertiaryFixedDim,
        onTertiary: AppColors.onTertiaryFixed,
        tertiaryContainer: AppColors.tertiary,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.errorContainer,
        onError: AppColors.onErrorContainer,
        errorContainer: AppColors.error,
        onErrorContainer: AppColors.onError,
        surface: Color(0xFF161B22),
        surfaceContainerLowest: Color(0xFF161B22),
        surfaceContainerLow: Color(0xFF1F242C),
        surfaceContainer: Color(0xFF282E38),
        surfaceContainerHigh: Color(0xFF323944),
        surfaceContainerHighest: Color(0xFF3D4653),
        onSurface: Color(0xFFF0F2F5),
        onSurfaceVariant: Color(0xFFC5CBD3),
        outline: Color(0xFF8D95A1),
        outlineVariant: Color(0xFF3D444D),
        inverseSurface: AppColors.surface,
        onInverseSurface: AppColors.onSurface,
        inversePrimary: AppColors.primary,
        surfaceTint: AppColors.primaryFixed,
      ),
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: const Color(0xFFF0F2F5)),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: const Color(0xFFF0F2F5)),
        displaySmall: AppTextStyles.displaySmall.copyWith(color: const Color(0xFFF0F2F5)),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: const Color(0xFFF0F2F5)),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: const Color(0xFFF0F2F5)),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(color: const Color(0xFFF0F2F5)),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: const Color(0xFFF0F2F5)),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: const Color(0xFFF0F2F5)),
        titleSmall: AppTextStyles.titleSmall.copyWith(color: const Color(0xFFF0F2F5)),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: const Color(0xFFF0F2F5)),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFFF0F2F5)),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: const Color(0xFFC5CBD3)),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: const Color(0xFFF0F2F5)),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: const Color(0xFFC5CBD3)),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: const Color(0xFFC5CBD3)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: const Color(0xFFF0F2F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.titleMedium.copyWith(
          color: AppColors.primaryFixed,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF161B22),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF3D444D), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F242C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF8D95A1).withValues(alpha: 0.6),
          fontSize: 14,
        ),
        labelStyle: AppTextStyles.labelMedium.copyWith(color: const Color(0xFFC5CBD3)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryFixed,
          foregroundColor: AppColors.onPrimaryFixed,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: AppColors.onPrimaryFixed,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryFixed,
          side: const BorderSide(color: Color(0xFF3D444D)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1F242C),
        selectedColor: AppColors.primary,
        labelStyle: AppTextStyles.labelMedium.copyWith(color: const Color(0xFFF0F2F5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: const Color(0xFF3D444D).withValues(alpha: 0.3),
        thickness: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryFixed;
          }
          return const Color(0xFF1F242C);
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

