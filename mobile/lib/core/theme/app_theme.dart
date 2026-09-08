import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Layout constants. Touch targets are deliberately larger than the Material
/// minimum: this app is used with wet hands on a moving deck.
abstract final class AppSizes {
  static const double gutter = 20;
  static const double gap = 14;
  static const double radius = 22;
  static const double radiusSmall = 16;

  /// Minimum height for anything tappable.
  static const double tapTarget = 64;
}

abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    background: AppColors.background,
    surface: AppColors.surface,
    ink: AppColors.ink,
    inkMuted: AppColors.inkMuted,
    hairline: AppColors.hairline,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    background: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    ink: AppColors.inkDark,
    inkMuted: AppColors.inkMutedDark,
    hairline: AppColors.hairlineDark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color ink,
    required Color inkMuted,
    required Color hairline,
  }) {
    // Type scale runs large throughout. Nothing meaningful is below 15sp.
    final textTheme = TextTheme(
      displayLarge: TextStyle(
        fontSize: 52,
        height: 1.05,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: ink,
      ),
      headlineLarge: TextStyle(
        fontSize: 30,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: TextStyle(fontSize: 17, height: 1.45, color: ink),
      bodyMedium: TextStyle(fontSize: 15.5, height: 1.45, color: inkMuted),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: ink,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.deepSea,
        brightness: brightness,
      ).copyWith(surface: surface, outlineVariant: hairline),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius),
          side: BorderSide(color: hairline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.tapTarget),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.deepSea.withValues(alpha: 0.12),
        height: 76,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: ink),
        ),
      ),
      dividerTheme: DividerThemeData(color: hairline, space: 1, thickness: 1),
    );
  }
}
