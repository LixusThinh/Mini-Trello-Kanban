import 'package:flutter/material.dart';

abstract final class AppColors {
  static const seed = Color(0xFF2E6B4F);
  static const background = Color(0xFFF1F7F1);
  static const mint = Color(0xFFA8EBCB);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.seed);
  final primaryButtonStyle = ButtonStyle(
    backgroundColor: const WidgetStatePropertyAll(AppColors.seed),
    foregroundColor: const WidgetStatePropertyAll(Colors.white),
    shape: const WidgetStatePropertyAll(StadiumBorder()),
    minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.background),
    filledButtonTheme: FilledButtonThemeData(style: primaryButtonStyle),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.mint,
      foregroundColor: AppColors.seed,
    ),
    inputDecorationTheme: const InputDecorationThemeData(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
  );
}
