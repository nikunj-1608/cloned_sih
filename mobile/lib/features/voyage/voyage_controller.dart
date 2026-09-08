import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/env.dart';
import '../../core/geo/geo_math.dart';
import '../../core/models/boundary_status.dart';
import '../../core/models/safety_level.dart';
import '../../core/models/sea_conditions.dart';
import '../map/demo_geo.dart';

/// Where the vessel is, where it is pointed, and how fast it is going.
class VoyageState {
  const VoyageState({
    required this.position,
    required this.headingDeg,
    required this.speedKnots,
    required this.underway,
  });

  final LatLng position;
  final double headingDeg;
  final double speedKnots;
  final bool underway;

  double get speedKmh => speedKnots * 1.852;

  VoyageState copyWith({
    LatLng? position,
    double? headingDeg,
    double? speedKnots,
    bool? underway,
  }) {
    return VoyageState(
      position: position ?? this.position,
      headingDeg: headingDeg ?? this.headingDeg,
      speedKnots: speedKnots ?? this.speedKnots,
      underway: underway ?? this.underway,
    );
  }
}

/// Drives [VoyageState].
///
/// In Phase 2 this is fed by the `geolocator` position stream. Until then, and
/// whenever `DEMO_MODE=true`, it replays a scripted track heading east-south-east
/// out of Rameswaram toward the IMBL, so the boundary alarm can be demonstrated
/// and filmed without taking a boat out. See `PROJECT_STATE.md`, blocker #6.
class VoyageController extends Notifier<VoyageState> {
  Timer? _ticker;

  @override
  VoyageState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const VoyageState(
      position: DemoGeo.homePort,
      headingDeg: 118,
      speedKnots: 0,
      underway: false,
    );
  }

  void toggleVoyage() => state.underway ? stopVoyage() : startVoyage();

  void startVoyage() {
    if (!Env.demoMode) {
      // Phase 2: subscribe to Geolocator.getPositionStream() here instead.
      state = state.copyWith(underway: true, speedKnots: 6.5);
      return;
    }

    state = state.copyWith(underway: true, speedKnots: 6.5);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _advance());
  }

  void stopVoyage() {
    _ticker?.cancel();
    _ticker = null;
    state = state.copyWith(underway: false, speedKnots: 0);
  }

  void resetToPort() {
    stopVoyage();
    state = const VoyageState(
      position: DemoGeo.homePort,
      headingDeg: 118,
      speedKnots: 0,
      underway: false,
    );
  }

  /// One second of real time compressed into two minutes of sailing, so the
  /// run out to the boundary fits inside a demo.
  void _advance() {
    const compression = 120;
    final stepKm = state.speedKmh / 3600 * compression;
    state = state.copyWith(
      position: GeoMath.destination(state.position, state.headingDeg, stepKm),
    );
  }
}

final voyageProvider = NotifierProvider<VoyageController, VoyageState>(
  VoyageController.new,
);

/// Distance and time to the nearest restricted boundary.
///
/// Computed entirely on-device from cached geometry. No network, no model.
final boundaryStatusProvider = Provider<BoundaryStatus>((ref) {
  final voyage = ref.watch(voyageProvider);
  final distanceKm = GeoMath.distanceToPolylineKm(voyage.position, DemoGeo.imbl);

  // "Approaching" is decided by whether the gap actually closes over the next
  // kilometre of travel, rather than by comparing bearings. That stays correct
  // when the boundary bends away from the vessel.
  final ahead = GeoMath.destination(voyage.position, voyage.headingDeg, 1);
  final distanceAheadKm = GeoMath.distanceToPolylineKm(ahead, DemoGeo.imbl);
  final closing = distanceAheadKm < distanceKm;

  int? minutes;
  if (voyage.underway && closing && voyage.speedKmh > 0.1) {
    minutes = (distanceKm / voyage.speedKmh * 60).round();
  }

  return BoundaryStatus(
    name: 'International Maritime Boundary',
    distanceKm: distanceKm,
    minutesToBreach: minutes,
    isApproaching: closing && voyage.underway,
  );
});

/// Marine conditions at the vessel's position.
///
/// Phase 1 returns a fixed snapshot. Phase 3 replaces this with a
/// `FutureProvider` calling `GET /v1/marine/conditions` and caching the result
/// to `sqflite` for use at sea.
final seaConditionsProvider = Provider<SeaConditions>((ref) {
  final boundary = ref.watch(boundaryStatusProvider);

  // Until the weather pipeline lands, the sea itself is calm and the only
  // thing that can raise the alert level is boundary proximity.
  final level = boundary.level;
  final summary = switch (level) {
    SafetyLevel.safe =>
      'Waves are low and the wind is steady. Good conditions until 6 PM today.',
    SafetyLevel.caution =>
      'Conditions are workable, but you are heading toward a restricted boundary.',
    SafetyLevel.danger =>
      'Turn back now. You are minutes from crossing the maritime boundary.',
  };

  return SeaConditions(
    level: level,
    summary: summary,
    waveHeightM: 0.8,
    windSpeedKmh: 12,
    visibilityKm: 9,
    observedAt: DateTime.now().subtract(const Duration(minutes: 24)),
  );
});
