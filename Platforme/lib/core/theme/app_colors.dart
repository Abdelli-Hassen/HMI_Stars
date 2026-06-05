import 'package:flutter/material.dart';

/// HMI Stars Design System — Color Tokens
/// Based on Material Design 3 tonal palette from DESIGN.md
class AppColors {
  AppColors._();

  // ─── Primary ───
  static const Color primary = Color(0xFFC59B27);
  static const Color primaryContainer = Color(0xFFE5B83B);
  static const Color onPrimary = Color(0xFF1C1917);
  static const Color onPrimaryContainer = Color(0xFF3D2F00);
  static const Color onPrimaryFixed = Color(0xFF3D2F00);
  static const Color onPrimaryFixedVariant = Color(0xFF574400);
  static const Color primaryFixed = Color(0xFFF2D574);
  static const Color primaryFixedDim = Color(0xFFE5C060);
  static const Color inversePrimary = Color(0xFFF2D574);

  // ─── Secondary ───
  static const Color secondary = Color(0xFF515F74);
  static const Color secondaryContainer = Color(0xFFD5E3FC);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF57657A);
  static const Color onSecondaryFixed = Color(0xFF0D1C2E);
  static const Color onSecondaryFixedVariant = Color(0xFF3A485B);
  static const Color secondaryFixed = Color(0xFFD5E3FC);
  static const Color secondaryFixedDim = Color(0xFFB9C7DF);

  // ─── Tertiary ───
  static const Color tertiary = Color(0xFF7B2600);
  static const Color tertiaryContainer = Color(0xFFA33500);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFFFC6B2);
  static const Color onTertiaryFixed = Color(0xFF380D00);
  static const Color onTertiaryFixedVariant = Color(0xFF812800);
  static const Color tertiaryFixed = Color(0xFFFFDBCF);
  static const Color tertiaryFixedDim = Color(0xFFFFB59B);

  // ─── Error ───
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ─── Surface / Background ───
  static const Color surface = Color(0xFFF7F9FB);
  static const Color surfaceBright = Color(0xFFF7F9FB);
  static const Color surfaceDim = Color(0xFFD8DADC);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceTint = Color(0xFF0C56D0);
  static const Color surfaceVariant = Color(0xFFE0E3E5);
  static const Color background = Color(0xFFF7F9FB);

  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF434654);
  static const Color onBackground = Color(0xFF191C1E);
  static const Color inverseSurface = Color(0xFF2D3133);
  static const Color inverseOnSurface = Color(0xFFEFF1F3);

  // ─── Outline ───
  static const Color outline = Color(0xFF737685);
  static const Color outlineVariant = Color(0xFFC3C6D6);

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );

  // ─── Sidebar ───
  static const Color sidebarBg = Color(0xFFF7F9FB);
  static const Color sidebarActiveBg = Color(0xFFFDF7E7);
  static const Color sidebarActiveText = primary;

  // ─── Status ───
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE65100);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color info = Color(0xFF0288D1);
  static const Color infoLight = Color(0xFFE1F5FE);
}
