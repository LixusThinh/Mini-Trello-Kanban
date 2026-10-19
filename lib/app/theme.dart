import 'package:flutter/material.dart';

import '../models/task.dart';

/// Bộ nhận diện "Indigo Focus" (contract-v2). Cố ý KHÁC bản demo của thầy:
/// không xanh lá/mint, không nút stadium, không input viền.
abstract final class AppColors {
  static const seed = Color(0xFF4F46E5); // indigo
  static const accent = Color(0xFF7C3AED); // violet, cặp gradient với seed
  static const lightBackground = Color(0xFFF6F5FB);
  static const darkBackground = Color(0xFF0F0E17);

  /// Gradient dùng cho hero màn auth và header.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [seed, accent],
  );

  /// Bảng màu thẻ dự án; chọn theo `projectId.hashCode % length`.
  static const projectPalette = <List<Color>>[
    [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    [Color(0xFF0EA5E9), Color(0xFF6366F1)],
    [Color(0xFFDB2777), Color(0xFF9333EA)],
    [Color(0xFF0D9488), Color(0xFF0284C7)],
    [Color(0xFFEA580C), Color(0xFFDB2777)],
  ];
}

/// Màu theo trạng thái task (dùng cho tab, sọc trái của thẻ, chip).
Color statusColor(TaskStatus s) => switch (s) {
  TaskStatus.todo => const Color(0xFF64748B), // slate
  TaskStatus.inProgress => const Color(0xFFEC4899), // pink
  TaskStatus.done => const Color(0xFF14B8A6), // teal
};

/// Icon theo trạng thái task.
IconData statusIcon(TaskStatus s) => switch (s) {
  TaskStatus.todo => Icons.radio_button_unchecked,
  TaskStatus.inProgress => Icons.timelapse_rounded,
  TaskStatus.done => Icons.task_alt_rounded,
};

const _radius = BorderRadius.all(Radius.circular(14));

ThemeData buildTheme([Brightness brightness = Brightness.light]) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: brightness,
  );
  final buttonShape = const WidgetStatePropertyAll(
    RoundedRectangleBorder(borderRadius: _radius),
  );
  const buttonSize = WidgetStatePropertyAll(Size.fromHeight(52));
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark
        ? AppColors.darkBackground
        : AppColors.lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(shape: buttonShape, minimumSize: buttonSize),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(shape: buttonShape, minimumSize: buttonSize),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: const RoundedRectangleBorder(borderRadius: _radius),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      border: const OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: _radius),
    ),
  );
}
