import 'package:flutter/material.dart';

class AppColors {
  // --- Brand Colors (Modern Ocean Cyan & Royal Indigo) ---
  static const Color primary = Color(0xFF0284C7); // Sky / Medical Cyan 600
  static const Color primaryDark = Color(0xFF0369A1); // Ocean 700
  static const Color primaryLight = Color(0xFFE0F2FE); // Soft Cyan 100
  static const Color accent = Color(0xFF4F46E5); // Modern Indigo
  static const Color accentLight = Color(0xFFEEF2FF); // Soft Indigo Tint

  // --- Neutral & Surface Colors ---
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFF1F5F9); // Slate 100
  static const Color borderDark = Color(0xFFCBD5E1); // Slate 300
  static const Color divider = Color(0xFFF1F5F9); // Slate 100

  // --- Sidebar Colors ---
  static const Color sidebarBg = Color(0xFF0B132B); // Rich Deep Navy
  static const Color sidebarHover = Color(0xFF1C2541); // Slate 800
  static const Color sidebarActive = Color(0xFF0284C7); // Cyan
  static const Color sidebarActiveBg = Color(0x260284C7); // Translucent Cyan Pill
  static const Color textOnSidebar = Color(0xFFF1F5F9);
  static const Color textOnSidebarMuted = Color(0xFF94A3B8);

  // --- Text Colors ---
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Colors.white;

  // --- Status & Semantic Colors ---
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successLight = Color(0xFFECFDF5); // Emerald 50
  static const Color successDark = Color(0xFF047857); // Emerald 700

  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFFFBEB); // Amber 50
  static const Color warningDark = Color(0xFFB45309); // Amber 700

  static const Color danger = Color(0xFFEF4444); // Red 500
  static const Color dangerLight = Color(0xFFFEF2F2); // Red 50
  static const Color dangerDark = Color(0xFFB91C1C); // Red 700

  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoLight = Color(0xFFEFF6FF); // Blue 50
  static const Color infoDark = Color(0xFF1D4ED8); // Blue 700

  // --- Capacity Indicator Colors ---
  static const Color capacityLow = Color(0xFF10B981); // < 50%
  static const Color capacityMedium = Color(0xFFF59E0B); // 50% - 80%
  static const Color capacityHigh = Color(0xFFEF4444); // >= 80%

  // --- Specialized Accents ---
  static const Color teal = Color(0xFF0D9488); // Teal 600
  static const Color tealLight = Color(0xFFF0FDFA);
  static const Color purple = Color(0xFF8B5CF6); // Purple 500
  static const Color purpleLight = Color(0xFFF5F3FF);

  // --- Modern Gradients ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [Color(0xFF0B132B), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
