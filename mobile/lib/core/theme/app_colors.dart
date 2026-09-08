import 'package:flutter/material.dart';

/// Palette tuned for use on an open boat: high contrast for direct sunlight,
/// and status meaning carried by colour first so that it reads without literacy.
abstract final class AppColors {
  // Brand
  static const Color deepSea = Color(0xFF0B4F6C);
  static const Color deepSeaDark = Color(0xFF073B52);
  static const Color horizon = Color(0xFF1B7FA8);

  // Status. These three are the most important colours in the app.
  static const Color safe = Color(0xFF0E7C4A);
  static const Color safeSoft = Color(0xFFE3F5EB);
  static const Color caution = Color(0xFFB26A00);
  static const Color cautionSoft = Color(0xFFFDF0DC);
  static const Color danger = Color(0xFFB3251E);
  static const Color dangerSoft = Color(0xFFFBE7E5);

  // Light surfaces
  static const Color background = Color(0xFFF4F7F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0E1A20);
  static const Color inkMuted = Color(0xFF56686F);
  static const Color hairline = Color(0xFFDDE5E8);

  // Dark surfaces (night sailing)
  static const Color backgroundDark = Color(0xFF081116);
  static const Color surfaceDark = Color(0xFF101D24);
  static const Color inkDark = Color(0xFFECF2F4);
  static const Color inkMutedDark = Color(0xFF93A7AF);
  static const Color hairlineDark = Color(0xFF23343C);

  // Map layers
  static const Color imbl = Color(0xFFC62828);
  static const Color mpa = Color(0xFFEF8C00);
  static const Color pfz = Color(0xFF14A05E);
  static const Color vessel = Color(0xFF0B4F6C);
}
