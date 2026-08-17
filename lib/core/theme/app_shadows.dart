import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  // Subtle shadow for cards, list items, badges
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x06000000),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x04000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  // Standard card elevation
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x040F172A),
      blurRadius: 6,
      offset: Offset(0, 1),
    ),
  ];

  // Floating elevated card (hover / active / selected)
  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x120F172A),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x060F172A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // Modal / Dialog elevation
  static const List<BoxShadow> dialog = [
    BoxShadow(
      color: Color(0x2E0F172A),
      blurRadius: 36,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x100F172A),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // Dropdown / Popover shadow
  static const List<BoxShadow> popover = [
    BoxShadow(
      color: Color(0x180F172A),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  // Glow for active/focused primary elements
  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.28),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // Glow for warning elements
  static List<BoxShadow> warningGlow = [
    BoxShadow(
      color: AppColors.warning.withValues(alpha: 0.28),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // Glow for success elements
  static List<BoxShadow> successGlow = [
    BoxShadow(
      color: AppColors.success.withValues(alpha: 0.28),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
