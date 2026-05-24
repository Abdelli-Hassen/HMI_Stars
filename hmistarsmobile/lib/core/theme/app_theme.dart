import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';

/// Access theme-aware colors via context.
/// Usage: context.cs.surface, context.cs.surfaceContainerLowest, etc.
extension ThemeContextExt on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
}

class AppColors {
  AppColors._();

  static bool get _isDark => AppState.isDarkStatic;

  // Primary palette - HMI Stars brand colors from prototype
  static Color get primary => _isDark ? const Color(0xFFA7C8FF) : const Color(0xFF001E40);
  static Color get onPrimary => _isDark ? const Color(0xFF002F65) : const Color(0xFFFFFFFF);
  static Color get primaryContainer => _isDark ? const Color(0xFF00458E) : const Color(0xFF003366);
  static Color get onPrimaryContainer => _isDark ? const Color(0xFFD4E3FF) : const Color(0xFF799DD6);
  static Color get primaryFixed => const Color(0xFFD5E3FF);
  static Color get primaryFixedDim => const Color(0xFFA7C8FF);

  // Secondary
  static Color get secondary => _isDark ? const Color(0xFFB4CAD6) : const Color(0xFF4C616C);
  static Color get onSecondary => _isDark ? const Color(0xFF1E333D) : const Color(0xFFFFFFFF);
  static Color get secondaryContainer => _isDark ? const Color(0xFF354A54) : const Color(0xFFCFE6F2);
  static Color get secondaryFixed => const Color(0xFFCFE6F2);
  static Color get secondaryFixedDim => const Color(0xFFB4CAD6);

  // Tertiary (Gold/Yellow - the accent)
  static Color get tertiary => _isDark ? const Color(0xFFEAC249) : const Color(0xFF745B00);
  static Color get onTertiary => _isDark ? const Color(0xFF3D2F00) : const Color(0xFFFFFFFF);
  static Color get tertiaryContainer => _isDark ? const Color(0xFF584400) : const Color(0xFFCCA72F);
  static Color get tertiaryFixed => const Color(0xFFFFE08B);
  static Color get tertiaryFixedDim => const Color(0xFFEAC249);

  // Surface containers
  static Color get surface => _isDark ? const Color(0xFF111416) : const Color(0xFFF8F9FA);
  static Color get surfaceBright => _isDark ? const Color(0xFF37393B) : const Color(0xFFF8F9FA);
  static Color get surfaceDim => _isDark ? const Color(0xFF111416) : const Color(0xFFD9DADB);
  static Color get surfaceContainer => _isDark ? const Color(0xFF1D2022) : const Color(0xFFEDEEEF);
  static Color get surfaceContainerLow => _isDark ? const Color(0xFF191C1E) : const Color(0xFFF3F4F5);
  static Color get surfaceContainerLowest => _isDark ? const Color(0xFF0C0F10) : const Color(0xFFFFFFFF);
  static Color get surfaceContainerHigh => _isDark ? const Color(0xFF272A2C) : const Color(0xFFE7E8E9);
  static Color get surfaceContainerHighest => _isDark ? const Color(0xFF323537) : const Color(0xFFE1E3E4);
  static Color get background => _isDark ? const Color(0xFF0D1117) : const Color(0xFFF8F9FA);

  // On-surface
  static Color get onSurface => _isDark ? const Color(0xFFE1E2E4) : const Color(0xFF191C1D);
  static Color get onSurfaceVariant => _isDark ? const Color(0xFFC3C6D1) : const Color(0xFF43474F);

  // Outline
  static Color get outline => _isDark ? const Color(0xFF8D9199) : const Color(0xFF737780);
  static Color get outlineVariant => _isDark ? const Color(0xFF43474F) : const Color(0xFFC3C6D1);

  // Error
  static Color get error => _isDark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A);
  static Color get onError => _isDark ? const Color(0xFF690005) : const Color(0xFFFFFFFF);
  static Color get errorContainer => _isDark ? const Color(0xFF93000A) : const Color(0xFFFFDAD6);

  // Inverse
  static Color get inverseSurface => _isDark ? const Color(0xFFE1E2E4) : const Color(0xFF2E3132);
  static Color get inverseOnSurface => _isDark ? const Color(0xFF191C1D) : const Color(0xFFF0F1F2);
  static Color get inversePrimary => _isDark ? const Color(0xFF00458E) : const Color(0xFFA7C8FF);

  // Status colors
  static Color get statusGreen => const Color(0xFF22C55E);
  static Color get statusOrange => const Color(0xFFF97316);
  static Color get statusRed => const Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSurface,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: const Color(0xFF4F3D00),
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: const Color(0xFF93000A),
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
        inversePrimary: AppColors.inversePrimary,
        surfaceTint: const Color(0xFF3A5F94),
      ),
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.manrope(
          fontSize: 57,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
        displayMedium: GoogleFonts.manrope(
          fontSize: 45,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
        headlineLarge: GoogleFonts.manrope(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        headlineSmall: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurface),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.onSurfaceVariant,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
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
          borderSide: BorderSide(color: AppColors.tertiary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.outlineVariant,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tertiary,
          foregroundColor: AppColors.onTertiary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          elevation: 0,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.tertiary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.onTertiary),
        side: BorderSide(color: AppColors.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.tertiary,
        unselectedItemColor: AppColors.outline,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface.withOpacity(0.9),
        elevation: 0,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withOpacity(0.05),
        titleTextStyle: GoogleFonts.manrope(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 20,
          letterSpacing: 2,
        ),
        iconTheme: IconThemeData(color: AppColors.primary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSurface,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onSurface,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onSurface,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
        inversePrimary: AppColors.inversePrimary,
        surfaceTint: AppColors.primary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(
          fontSize: 57,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
        ),
        displayMedium: GoogleFonts.manrope(
          fontSize: 45,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
        ),
        headlineLarge: GoogleFonts.manrope(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF0F2F5),
        ),
        headlineSmall: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF0F2F5),
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF0F2F5),
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF0F2F5),
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF0F2F5),
          letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xFFF0F2F5)),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFF0F2F5)),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: const Color(0xFFC5CBD3),
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: const Color(0xFFF0F2F5),
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: const Color(0xFFC5CBD3),
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: const Color(0xFFC5CBD3),
        ),
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
          borderSide: const BorderSide(color: Color(0xFFF2D574), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF8D95A1),
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF2D574),
          foregroundColor: const Color(0xFF3D2F00),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          elevation: 0,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        titleTextStyle: GoogleFonts.manrope(
          color: const Color(0xFFC4D7F5),
          fontWeight: FontWeight.w900,
          fontSize: 20,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFC4D7F5)),
      ),
    );
  }
}

