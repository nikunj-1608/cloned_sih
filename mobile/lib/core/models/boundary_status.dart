import 'safety_level.dart';

/// Proximity to the nearest restricted boundary.
///
/// [minutesToBreach] is the headline figure rather than [distanceKm]: at the
/// helm, "40 minutes away" is actionable in a way that "12 kilometres" is not.
/// It is derived on-device from GPS course and speed over ground.
class BoundaryStatus {
  const BoundaryStatus({
    required this.name,
    required this.distanceKm,
    required this.minutesToBreach,
    required this.isApproaching,
  });

  final String name;
  final double distanceKm;

  /// Null when the vessel is stationary or heading away from the boundary.
  final int? minutesToBreach;
  final bool isApproaching;

  SafetyLevel get level {
    if (!isApproaching) return SafetyLevel.safe;
    final minutes = minutesToBreach;
    if (minutes == null) return SafetyLevel.safe;
    if (minutes <= 15) return SafetyLevel.danger;
    if (minutes <= 45) return SafetyLevel.caution;
    return SafetyLevel.safe;
  }

  String get headline {
    final minutes = minutesToBreach;
    if (!isApproaching || minutes == null) {
      return '${distanceKm.toStringAsFixed(0)} km away';
    }
    if (minutes < 60) return '$minutes minutes away';
    final hours = minutes ~/ 60;
    return  '$hours hr ${minutes % 60} min away';
  }
}
