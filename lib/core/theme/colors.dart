import 'package:flutter/material.dart';

/// Palet koulè Redlight Autoparts — rouj / nwa / blan.
abstract final class AppColors {
  static const red = Color(0xFFE10600);
  static const redDark = Color(0xFFA80400);

  // Dark theme (app kliyan)
  static const black = Color(0xFF0A0A0A);
  static const surfaceDark = Color(0xFF1A1A1A);
  static const surfaceDarkElevated = Color(0xFF1E222B);
  static const borderDark = Color(0xFF2E2E2E);
  static const borderDarkSubtle = Color(0xFF373D4B);
  static const textMutedDark = Color(0xFF9CA3AF);

  // Light theme (panel admin)
  static const white = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF4F4F5);
  static const surfaceLightElevated = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE4E4E7);
  static const borderLightSubtle = Color(0xFFE2E8F0);
  static const textMutedLight = Color(0xFF6B7280);

  // Estati
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);
  static const violet = Color(0xFF8B5CF6);
}

/// Lonbray ak efè pwofondè ("effet profond") pou kat yo.
abstract final class AppShadows {
  /// Lonbray fon doub-kouch pou mòd nwa (tactile & immersive).
  static const List<BoxShadow> darkElevated = [
    BoxShadow(
      color: Color(0x80000000),
      blurRadius: 18,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 6,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  /// Lonbray fon doub-kouch pou mòd klè.
  static const List<BoxShadow> lightElevated = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      spreadRadius: 0,
      offset: Offset(0, 1),
    ),
  ];

  /// Lonbray sibtil pou ti eleman yo (mòd nwa).
  static const List<BoxShadow> darkSubtle = [
    BoxShadow(
      color: Color(0x59000000),
      blurRadius: 10,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  /// Lonbray sibtil pou ti eleman yo (mòd klè).
  static const List<BoxShadow> lightSubtle = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 8,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> elevated(bool isDark) =>
      isDark ? darkElevated : lightElevated;

  static List<BoxShadow> subtle(bool isDark) =>
      isDark ? darkSubtle : lightSubtle;
}
