import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/theme.dart';

class AppTypography {
  // --- Headings & Display (Outfit) ---
  static TextStyle get h1 => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get h3 => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get h4 => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get h5 => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // --- Body Text (Inter) ---
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textMuted,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: AppColors.textMuted,
      );

  // --- Form & UI Elements (Inter) ---
  static TextStyle get formLabel => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get formHint => GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.textMuted,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get buttonSmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get badge => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get badgeSmall => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.bold,
      );

  // --- Metrics & Numbers (Outfit) ---
  static TextStyle get kpiValue => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get kpiLabel => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      );

  static TextStyle get toothNumber => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );
}






