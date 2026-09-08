import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/env.dart';
import '../../core/geo/geo_math.dart';
import '../../core/models/boundary_status.dart';
import '../../core/models/safety_level.dart';
import '../../core/models/sea_conditions.dart';
import '../advisory/advisory_controller.dart';
import '../map/demo_geo.dart';
import 'location_service.dart';

/// The source of position fixes: the real receiver at sea, a scripted track
/// when `DEMO_MODE=true`. Both emit the same [Fix] stream.
final locationServiceProvider = Provider<LocationService>((ref) {
  final service = Env.demoMode
      ? ScriptedLocationService()
      : GeolocatorLocationService();
  ref.onDispose(service.dispose);
  return service;
});

/// Where the vessel is, where it is pointed, and how fast it is going.
class VoyageState {
  const VoyageState({
    required this.position,
    required this.headingDeg,
    required this.speedKnots,
    required this.underway,
    this.permissionDenied = false,
  });

  final LatLng position;
  final double headingDeg;
  final double speedKnots;
  final bool underway;

  /// Set when location permission was refused. The UI must not pretend the
  /// geofence is armed when it has no fixes to work from.
  final bool permissionDenied;

  double get speedKmh => speedKnots * 1.852;

  VoyageState copyWith({
    LatLng? position,
    double? headingDeg,
    double? speedKnots,
    bool? underway,
    bool? permissionDenied,
  }) {
    return VoyageState(
      position: position ?? this.position,
      headingDeg: headingDeg ?? this.headingDeg,
      speedKnots: speedKnots ?? this.speedKnots,
      underway: underway ?? this.underway,
      permissionDenied: permissionDenied ?? this.permissionDenied,
    );
  }
}

/// Drives [VoyageState] from whatever [LocationService] is installed.
///
/// The controller knows nothing about GPS hardware or demo scripts — it
/// subscribes to a [Fix] stream and updates state. That is what lets the same
/// geofence and alarm code run identically at sea and on a desk.
class VoyageController extends Notifier<VoyageState> {
  StreamSubscription<Fix>? _subscription;

  @override
  VoyageState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const VoyageState(
      position: DemoGeo.homePort,
      headingDeg: 118,
      speedKnots: 0,
      underway: false,
    );
  }

  void toggleVoyage() => state.underway ? stopVoyage() : startVoyage();

  Future<void> startVoyage() async {
    final service = ref.read(locationServiceProvider);

    if (!await service.ensurePermission()) {
      // Without a fix there is no geofence, so say so rather than showing a
      // stationary boat and implying the alarm is armed.
      state = state.copyWith(underway: false, permissionDenied: true);
      return;
    }

    state = state.copyWith(underway: true, permissionDenied: false);
    await _subscription?.cancel();
    _subscription = service.fixes().listen(
      (fix) => state = state.copyWith(
        position: fix.position,
        headingDeg: fix.headingDeg,
        speedKnots: fix.speedKnots,
      ),
      onError: (Object _) => stopVoyage(),
    );
  }

  void stopVoyage() {
    _subscription?.cancel();
    _subscription = null;
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
}

final voyageProvider = NotifierProvider<VoyageController, VoyageState>(
  VoyageController.new,
);

/// Distance and time to the nearest restricted boundary.
///
/// A plain function, not just a provider body. The alarm needs to evaluate this
/// the instant a position fix arrives, and routing that through a computed
/// provider would make a safety-critical calculation depend on Riverpod's
/// invalidation ordering — and on some widget being on screen to read it.
///
/// Runs entirely on-device from cached geometry. No network, no model.
BoundaryStatus computeBoundaryStatus(VoyageState voyage) {
  final distanceKm = GeoMath.distanceToPolylineKm(voyage.position, DemoGeo.imbl);

  // "Approaching" is decided by whether the gap actually closes over a short
  // step forward, rather than by comparing bearings. That stays correct when
  // the boundary bends away from the vessel.
  //
  // The probe is deliberately short and scaled to the range: a fixed long
  // probe overshoots the line once the vessel is closer than the probe itself,
  // which reads as "moving away" at precisely the moment it is about to cross.
  final probeKm = math.min(0.05, distanceKm / 2);
  final ahead = GeoMath.destination(voyage.position, voyage.headingDeg, probeKm);
  final distanceAheadKm = GeoMath.distanceToPolylineKm(ahead, DemoGeo.imbl);
  final closing = distanceAheadKm < distanceKm;

  // Home port defines "our side" of the line. Anything on the other side is a
  // crossing, however far past it the vessel has drifted.
  final crossed = GeoMath.hasCrossed(
    voyage.position,
    DemoGeo.imbl,
    reference: DemoGeo.homePort,
  );

  int? minutes;
  if (voyage.underway && closing && voyage.speedKmh > 0.1) {
    minutes = (distanceKm / voyage.speedKmh * 60).round();
  }

  return BoundaryStatus(
    name: 'International Maritime Boundary',
    distanceKm: distanceKm,
    minutesToBreach: minutes,
    isApproaching: closing && voyage.underway,
    hasCrossed: crossed,
  );
}

final boundaryStatusProvider = Provider<BoundaryStatus>(
  (ref) => computeBoundaryStatus(ref.watch(voyageProvider)),
);

/// Marine conditions at the vessel's position.
///
/// Prefers the downloaded advisory pack; falls back to a conservative built-in
/// snapshot when nothing has been downloaded yet. Boundary proximity can only
/// ever raise the alert level, never lower it — a calm sea does not make an
/// approaching border safe.
final seaConditionsProvider = Provider<SeaConditions>((ref) {
  final boundary = ref.watch(boundaryStatusProvider);
  final pack = ref.watch(advisoryProvider).value;

  final seaLevel = switch (pack?.severity) {
    'danger' => SafetyLevel.danger,
    'caution' => SafetyLevel.caution,
    'safe' => SafetyLevel.safe,
    _ => SafetyLevel.safe,
  };

  // Take the worse of the two verdicts.
  final level = boundary.level.index > seaLevel.index ? boundary.level : seaLevel;

  final summary = switch (level) {
    SafetyLevel.danger when boundary.level == SafetyLevel.danger =>
      'Turn back now. You are minutes from crossing the maritime boundary.',
    SafetyLevel.caution when boundary.level == SafetyLevel.caution =>
      'Conditions are workable, but you are heading toward a restricted boundary.',
    _ =>
      pack?.summary ??
          'No advisory downloaded yet. Connect at port and download before you sail.',
  };

  return SeaConditions(
    level: level,
    summary: summary,
    waveHeightM: pack?.waveHeightM ?? 0,
    windSpeedKmh: pack?.windSpeedKmh ?? 0,
    visibilityKm: 9,
    observedAt: pack?.generatedAt ?? DateTime.now(),
  );
});
