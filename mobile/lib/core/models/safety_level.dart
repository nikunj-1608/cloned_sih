import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'bilingual.dart';

/// The single most important piece of state in the app: may this boat go out?
///
/// Deliberately three values, not a numeric score. A fisherman standing on a
/// jetty at 4am needs an answer, not a probability.
enum SafetyLevel {
  safe(
    label: Bilingual('Safe to go', 'கடலுக்குச் செல்லலாம்'),
    color: AppColors.safe,
    softColor: AppColors.safeSoft,
    icon: Icons.check_circle_rounded,
  ),
  caution(
    label: Bilingual('Be careful', 'கவனமாக இருங்கள்'),
    color: AppColors.caution,
    softColor: AppColors.cautionSoft,
    icon: Icons.warning_amber_rounded,
  ),
  danger(
    label: Bilingual('Do not go', 'கடலுக்குச் செல்ல வேண்டாம்'),
    color: AppColors.danger,
    softColor: AppColors.dangerSoft,
    icon: Icons.dangerous_rounded,
  );

  const SafetyLevel({
    required this.label,
    required this.color,
    required this.softColor,
    required this.icon,
  });

  final Bilingual label;
  final Color color;
  final Color softColor;
  final IconData icon;
}
