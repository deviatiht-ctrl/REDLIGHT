import 'package:flutter/material.dart';

/// Palet koulè Redlight Automotive — rouj / nwa / blan.
abstract final class AppColors {
  static const red = Color(0xFFE10600);
  static const redDark = Color(0xFFA80400);

  // Dark theme (app kliyan)
  static const black = Color(0xFF0A0A0A);
  static const surfaceDark = Color(0xFF1A1A1A);
  static const borderDark = Color(0xFF2E2E2E);
  static const textMutedDark = Color(0xFF9CA3AF);

  // Light theme (panel admin)
  static const white = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF4F4F5);
  static const borderLight = Color(0xFFE4E4E7);
  static const textMutedLight = Color(0xFF6B7280);

  // Estati
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);
  static const violet = Color(0xFF8B5CF6);
}
