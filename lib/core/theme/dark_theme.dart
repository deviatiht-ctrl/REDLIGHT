import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Tèm SOMBRE pou app kliyan — nwa + rouj + blan.
ThemeData buildDarkTheme() {
  final textTheme = GoogleFonts.dmSansTextTheme(
    ThemeData.dark(useMaterial3: true).textTheme,
  ).apply(bodyColor: AppColors.white, displayColor: AppColors.white);

  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.borderDark),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.black,
    textTheme: textTheme,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.red,
      onPrimary: AppColors.white,
      secondary: AppColors.red,
      onSecondary: AppColors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.white,
      error: AppColors.red,
      onError: AppColors.white,
      outline: AppColors.borderDark,
      surfaceContainerHighest: AppColors.borderDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.white),
      titleTextStyle: TextStyle(
        color: AppColors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderDark),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      hintStyle: const TextStyle(color: AppColors.textMutedDark),
      labelStyle: const TextStyle(color: AppColors.textMutedDark),
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
        disabledBackgroundColor: AppColors.borderDark,
        disabledForegroundColor: AppColors.textMutedDark,
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
        foregroundColor: AppColors.white,
        minimumSize: const Size(48, 52),
        side: const BorderSide(color: AppColors.borderDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.red),
    ),
    iconTheme: const IconThemeData(color: AppColors.white),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      contentTextStyle: textTheme.bodyMedium,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderDark,
      thickness: 1,
      space: 1,
    ),
    chipTheme: baseChipTheme(textTheme, AppColors.surfaceDark, AppColors.borderDark, AppColors.white),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.red),
    radioTheme: const RadioThemeData(
      fillColor: WidgetStatePropertyAll(AppColors.red),
    ),
  );
}

ChipThemeData baseChipTheme(
  TextTheme textTheme,
  Color background,
  Color border,
  Color label,
) {
  return ChipThemeData(
    backgroundColor: background,
    selectedColor: AppColors.red,
    disabledColor: background,
    labelStyle: textTheme.bodyMedium?.copyWith(color: label),
    secondaryLabelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.white),
    side: BorderSide(color: border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );
}
