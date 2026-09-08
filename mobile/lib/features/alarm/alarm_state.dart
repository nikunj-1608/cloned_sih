import 'package:flutter/material.dart';

import '../../core/models/bilingual.dart';
import '../../core/theme/app_colors.dart';

/// How urgently the vessel must react.
///
/// Escalation is driven by **time to breach**, not raw distance. At the helm,
/// "12 minutes" is actionable in a way that "4 kilometres" is not: it already
/// accounts for how fast you are going and which way you are pointed.
enum AlarmLevel {
  none(
    minutesThreshold: null,
    title: Bilingual('Clear', 'பாதுகாப்பு'),
    color: AppColors.safe,
    icon: Icons.check_circle_rounded,
  ),

  /// Enough time to finish a haul and turn calmly.
  advisory(
    minutesThreshold: 45,
    title: Bilingual('Border ahead', 'எல்லை அருகில்'),
    color: AppColors.caution,
    icon: Icons.info_rounded,
  ),

  /// Turn now.
  warning(
    minutesThreshold: 15,
    title: Bilingual('Turn back soon', 'விரைவில் திரும்புங்கள்'),
    color: Color(0xFFE07800),
    icon: Icons.warning_amber_rounded,
  ),

  /// Minutes from crossing an international boundary.
  critical(
    minutesThreshold: 5,
    title: Bilingual('TURN BACK NOW', 'இப்போதே திரும்புங்கள்'),
    color: AppColors.danger,
    icon: Icons.dangerous_rounded,
  ),

  /// Already inside restricted water.
  breached(
    minutesThreshold: 0,
    title: Bilingual('YOU HAVE CROSSED', 'எல்லையைக் கடந்துவிட்டீர்கள்'),
    color: Color(0xFF8B0000),
    icon: Icons.gpp_bad_rounded,
  );

  const AlarmLevel({
    required this.minutesThreshold,
    required this.title,
    required this.color,
    required this.icon,
  });

  /// Fire this level at or below this many minutes to breach.
  final int? minutesThreshold;
  final Bilingual title;
  final Color color;
  final IconData icon;

  bool get isActive => this != AlarmLevel.none;

  /// Only the top two levels take over the screen. An advisory 45 minutes out
  /// must not blank the chart someone is steering by.
  bool get takesOverScreen =>
      this == AlarmLevel.critical || this == AlarmLevel.breached;

  bool get soundsSiren => takesOverScreen || this == AlarmLevel.warning;

  /// Escalation is one-way within a trip: an alarm never quietly downgrades
  /// itself while the vessel is still closing on the boundary.
  bool isHigherThan(AlarmLevel other) => index > other.index;
}

class AlarmState {
  const AlarmState({
    required this.level,
    required this.acknowledgedLevel,
    required this.boundaryName,
    required this.distanceKm,
    required this.minutesToBreach,
  });

  const AlarmState.clear()
    : level = AlarmLevel.none,
      acknowledgedLevel = AlarmLevel.none,
      boundaryName = '',
      distanceKm = 0,
      minutesToBreach = null;

  final AlarmLevel level;

  /// The highest level the user has dismissed. A dismissed alarm stays quiet
  /// until the situation gets worse, then re-arms on its own.
  final AlarmLevel acknowledgedLevel;

  final String boundaryName;
  final double distanceKm;
  final int? minutesToBreach;

  /// Whether the alarm should currently be in the user's face.
  bool get isRinging => level.isActive && level.isHigherThan(acknowledgedLevel);

  bool get shouldTakeOverScreen => isRinging && level.takesOverScreen;

  String get timeLabel {
    final minutes = minutesToBreach;
    if (minutes == null) return '${distanceKm.toStringAsFixed(1)} km away';
    if (minutes <= 0) return 'Crossed';
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60} hr ${minutes % 60} min';
  }

  AlarmState copyWith({
    AlarmLevel? level,
    AlarmLevel? acknowledgedLevel,
    String? boundaryName,
    double? distanceKm,
    int? minutesToBreach,
    bool clearMinutes = false,
  }) {
    return AlarmState(
      level: level ?? this.level,
      acknowledgedLevel: acknowledgedLevel ?? this.acknowledgedLevel,
      boundaryName: boundaryName ?? this.boundaryName,
      distanceKm: distanceKm ?? this.distanceKm,
      minutesToBreach: clearMinutes ? null : (minutesToBreach ?? this.minutesToBreach),
    );
  }
}
