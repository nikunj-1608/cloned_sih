import 'safety_level.dart';

/// A snapshot of marine conditions for one position and time.
///
/// [observedAt] is not decoration. Offline, this data ages, and the UI degrades
/// its confidence visibly as it does. See [ageLabel].
class SeaConditions {
  const SeaConditions({
    required this.level,
    required this.summary,
    required this.waveHeightM,
    required this.windSpeedKmh,
    required this.visibilityKm,
    required this.observedAt,
  });

  final SafetyLevel level;
  final String summary;
  final double waveHeightM;
  final double windSpeedKmh;
  final double visibilityKm;
  final DateTime observedAt;

  Duration get age => DateTime.now().difference(observedAt);

  /// Data older than six hours is no longer trustworthy for a departure call.
  bool get isStale => age.inHours >= 6;

  String get ageLabel {
    final minutes = age.inMinutes;
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return '$minutes min ago';
    final hours = age.inHours;
    if (hours < 24) return '$hours hr ago';
    return '${age.inDays} days ago';
  }
}
