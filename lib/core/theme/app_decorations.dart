import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_shadows.dart';

class AppDecorations {
  // Standard Card Decoration
  static BoxDecoration card = BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.borderRadiusXxl,
    border: Border.all(color: AppColors.border, width: 1),
    boxShadow: AppShadows.subtle,
  );

  // Compact Card / Panel Decoration
  static BoxDecoration panel = BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.borderRadiusXl,
    border: Border.all(color: AppColors.border, width: 1),
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
    border: Border.all(color: AppColors.border, width: 1),
    boxShadow: AppShadows.dialog,
  );

  // Selected / Active List Item
  static BoxDecoration selectedItem = BoxDecoration(
    color: AppColors.primaryLight,
    borderRadius: AppRadius.borderRadiusLg,
    border: Border.all(
      color: AppColors.primary.withValues(alpha: 0.4),
      width: 1.2,
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
          color: textColor.withValues(alpha: 0.25),
          width: 1,
        ),
      );

  // Warning Banner Box
  static BoxDecoration warningBanner = BoxDecoration(
    color: AppColors.warningLight,
    borderRadius: AppRadius.borderRadiusLg,
    border: Border.all(
      color: AppColors.warning.withValues(alpha: 0.5),
      width: 1,
    ),
  );

  // Medical Alert Banner Box
  static BoxDecoration alertTag = BoxDecoration(
    color: AppColors.warningLight,
    borderRadius: AppRadius.borderRadiusSm,
    border: Border.all(
      color: AppColors.warning.withValues(alpha: 0.5),
      width: 1,
    ),
  );
}






