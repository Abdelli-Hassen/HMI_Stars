import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// HMI Stars Design System — Typography
/// Dual-font system: Manrope (headlines) + Inter (body/labels)
class AppTextStyles {
  AppTextStyles._();

  // ─── Headline / Display (Manrope) ───
  static TextStyle displayLarge = GoogleFonts.manrope(
    fontSize: 57,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.25,
    color: AppColors.onSurface,
  );

  static TextStyle displayMedium = GoogleFonts.manrope(
    fontSize: 45,
    fontWeight: FontWeight.w800,
    color: AppColors.onSurface,
  );

  static TextStyle displaySmall = GoogleFonts.manrope(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.onSurface,
  );

  static TextStyle headlineLarge = GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.onSurface,
  );

  static TextStyle headlineMedium = GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );

  static TextStyle headlineSmall = GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );

  static TextStyle titleLarge = GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle titleMedium = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.15,
    color: AppColors.onSurface,
  );

  static TextStyle titleSmall = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.onSurface,
  );

  // ─── Body (Inter) ───
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.onSurface,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.onSurface,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: AppColors.onSurfaceVariant,
  );

  // ─── Label (Inter) ───
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.onSurface,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
  );
}
