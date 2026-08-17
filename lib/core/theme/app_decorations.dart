import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_shadows.dart';

class AppDecorations {
  // Standard Modern Card Decoration
  static BoxDecoration card = BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.borderRadiusXxl,
    border: Border.all(color: AppColors.border, width: 1),
    boxShadow: AppShadows.card,
  );

  // Elevated Floating Card Decoration (for KPIs, active elements)
  static BoxDecoration cardElevated = BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.borderRadiusXxl,
    border: Border.all(color: AppColors.borderLight, width: 1),
    boxShadow: AppShadows.floating,
  );

  // Compact Card / Panel Decoration
  static BoxDecoration panel = BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.borderRadiusXl,
    border: Border.all(color: AppColors.border, width: 1),
    boxShadow: AppShadows.subtle,
  );

  // Background Tone Panel Decoration
  static BoxDecoration panelBg = BoxDecoration(
    color: AppColors.background,
    borderRadius: AppRadius.borderRadiusLg,
    border: Border.all(color: AppColors.border, width: 1),
  );

  // Dialog Decoration
  static BoxDecoration dialog = BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.borderRadiusXxl,
    border: Border.all(color: AppColors.borderLight, width: 1),
    boxShadow: AppShadows.dialog,
  );

  // Selected / Active List Item
  static BoxDecoration selectedItem = BoxDecoration(
    color: AppColors.primaryLight.withValues(alpha: 0.6),
    borderRadius: AppRadius.borderRadiusLg,
    border: Border.all(
      color: AppColors.primary.withValues(alpha: 0.6),
      width: 1.5,
    ),
  );

  // Hovered List Item
  static BoxDecoration hoverItem = BoxDecoration(
    color: AppColors.background,
    borderRadius: AppRadius.borderRadiusLg,
    border: Border.all(color: AppColors.border, width: 1.2),
  );

  // Inactive / Default List Item
  static BoxDecoration defaultItem = BoxDecoration(
    color: Colors.transparent,
    borderRadius: AppRadius.borderRadiusLg,
    border: Border.all(color: Colors.transparent, width: 1.2),
  );

  // Icon Badge / Avatar Box
  static BoxDecoration iconBadge(Color color, {double radius = AppRadius.md}) =>
      BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      );

  // Status Pill / Tag
  static BoxDecoration statusBadge(Color textColor, Color bgColor) =>
      BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.borderRadiusPill,
        border: Border.all(
          color: textColor.withValues(alpha: 0.2),
          width: 1,
        ),
      );

  // Warning Banner Box
  static BoxDecoration warningBanner = BoxDecoration(
    color: AppColors.warningLight,
    borderRadius: AppRadius.borderRadiusLg,
    border: Border.all(
      color: AppColors.warning.withValues(alpha: 0.3),
      width: 1,
    ),
  );

  // Medical Alert Banner Box
  static BoxDecoration alertTag = BoxDecoration(
    color: AppColors.warningLight,
    borderRadius: AppRadius.borderRadiusSm,
    border: Border.all(
      color: AppColors.warning.withValues(alpha: 0.3),
      width: 1,
    ),
  );

  // Header / Topbar glass effect
  static BoxDecoration glassHeader = BoxDecoration(
    color: AppColors.surface.withValues(alpha: 0.95),
    border: const Border(
      bottom: BorderSide(color: AppColors.border, width: 1),
    ),
  );
}
