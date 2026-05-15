import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Access theme-aware colors via context.
/// Usage: context.cs.surface, context.cs.surfaceContainerLowest, etc.
extension ThemeContextExt on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
}

class AppColors {
  // Primary palette - HMI Stars brand colors from prototype
  static const Color primary = Color(0xFF001E40);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF003366);
  static const Color onPrimaryContainer = Color(0xFF799DD6);
  static const Color primaryFixed = Color(0xFFD5E3FF);
  static const Color primaryFixedDim = Color(0xFFA7C8FF);

  // Secondary
  static const Color secondary = Color(0xFF4C616C);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFCFE6F2);
  static const Color secondaryFixed = Color(0xFFCFE6F2);
  static const Color secondaryFixedDim = Color(0xFFB4CAD6);

  // Tertiary (Gold/Yellow - the accent)
  static const Color tertiary = Color(0xFF745B00);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFCCA72F);
  static const Color tertiaryFixed = Color(0xFFFFE08B);
  static const Color tertiaryFixedDim = Color(0xFFEAC249);

  // Surface containers
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceBright = Color(0xFFF8F9FA);
  static const Color surfaceDim = Color(0xFFD9DADB);
  static const Color surfaceContainer = Color(0xFFEDEEEF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E4);

  // On-surface
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF43474F);

  // Outline
  static const Color outline = Color(0xFF737780);
  static const Color outlineVariant = Color(0xFFC3C6D1);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // Inverse
  static const Color inverseSurface = Color(0xFF2E3132);
  static const Color inverseOnSurface = Color(0xFFF0F1F2);
  static const Color inversePrimary = Color(0xFFA7C8FF);

  // Status colors
  static const Color statusGreen = Color(0xFF22C55E);
  static const Color statusOrange = Color(0xFFF97316);
  static const Color statusRed = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
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
        onTertiaryContainer: Color(0xFF4F3D00),
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: Color(0xFF93000A),
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
        inversePrimary: AppColors.inversePrimary,
        surfaceTint: Color(0xFF3A5F94),
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
          borderSide: const BorderSide(color: AppColors.tertiary, width: 1.5),
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
        side: const BorderSide(color: AppColors.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
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
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        // Softer light blue for primary elements and text (easier on the eyes)
        primary: Color(0xFFC4D7F5),
        onPrimary: Color(0xFF00325A),
        // Primary container - distinct but soft
        primaryContainer: Color(0xFF1E4060),
        onPrimaryContainer: Color(0xFFE2EDFF),
        secondary: Color(0xFFB4CAD6),
        onSecondary: Color(0xFF1F333E),
        secondaryContainer: Color(0xFF354A54),
        onSecondaryContainer: Color(0xFFCFE6F2),
        tertiary: Color(0xFFF2D574), // Lighter yellow/gold for accents
        onTertiary: Color(0xFF3D2F00),
        tertiaryContainer: Color(0xFF574400),
        onTertiaryContainer: Color(0xFFFFE08B),
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        // Softer dark grey backgrounds (not pure or near black)
        surface: Color(0xFF1C2128),
        onSurface: Color(0xFFF0F2F5), // Brighter text for clear writing
        onSurfaceVariant: Color(0xFFC5CBD3), // Softer grey for subtitles
        surfaceContainerLowest: Color(0xFF15191E),
        surfaceContainerLow: Color(0xFF222831),
        surfaceContainer: Color(0xFF2D3540),
        surfaceContainerHigh: Color(0xFF384350),
        surfaceContainerHighest: Color(0xFF44505F),
        outline: Color(0xFF8D95A1),
        outlineVariant: Color(0xFF555D68),
        inverseSurface: Color(0xFFE1E3E5),
        onInverseSurface: Color(0xFF2E3132),
        inversePrimary: Color(0xFF001E40),
        surfaceTint: Color(0xFFC4D7F5),
      ),
      scaffoldBackgroundColor: const Color(
        0xFF15191E,
      ), // Comfortable dark background
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF222831),
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
        backgroundColor: const Color(0xFF1C2128),
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
