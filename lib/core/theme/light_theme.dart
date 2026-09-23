import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'dark_theme.dart' show baseChipTheme;

/// Tèm CLÈ pou panel admin web — blan + rouj aksan + tèks nwa.
ThemeData buildLightTheme() {
  final textTheme = GoogleFonts.dmSansTextTheme(
    ThemeData.light(useMaterial3: true).textTheme,
  ).apply(bodyColor: AppColors.black, displayColor: AppColors.black);

  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.borderLight),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.surfaceLight,
    textTheme: textTheme,
    colorScheme: const ColorScheme.light(
      primary: AppColors.red,
      onPrimary: AppColors.white,
      secondary: AppColors.red,
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.black,
      error: AppColors.red,
      onError: AppColors.white,
      outline: AppColors.borderLight,
      surfaceContainerHighest: AppColors.surfaceLight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.black),
      titleTextStyle: TextStyle(
        color: AppColors.black,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      hintStyle: const TextStyle(color: AppColors.textMutedLight),
      labelStyle: const TextStyle(color: AppColors.textMutedLight),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.red,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.borderLight,
        disabledForegroundColor: AppColors.textMutedLight,
        minimumSize: const Size(48, 52),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.black,
        minimumSize: const Size(48, 52),
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.red),
    ),
    iconTheme: const IconThemeData(color: AppColors.black),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.black,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
      space: 1,
    ),
    chipTheme: baseChipTheme(textTheme, AppColors.white, AppColors.borderLight, AppColors.black),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.red),
    radioTheme: const RadioThemeData(
      fillColor: WidgetStatePropertyAll(AppColors.red),
    ),
    dataTableTheme: const DataTableThemeData(
      headingTextStyle: TextStyle(
        color: AppColors.textMutedLight,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    ),
  );
}
