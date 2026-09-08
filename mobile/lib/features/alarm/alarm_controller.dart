import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/geo/geo_math.dart';
import '../map/demo_geo.dart';
import '../voyage/voyage_controller.dart';
import 'alarm_siren.dart';
import 'alarm_state.dart';

/// The offline safety kernel's output stage.
///
/// Everything upstream of this — position, distance, time to breach — is
/// computed on-device from cached geometry with no network and no model in the
/// loop. This class turns that into something a person on a loud, wet deck
/// cannot miss: sound, vibration, and a screen they must dismiss.
class AlarmController extends Notifier<AlarmState> {
  AlarmLevel _lastSounded = AlarmLevel.none;

  /// Resolved once per build. Reading it lazily would mean calling `ref.read`
  /// from inside a listener or a dispose callback, which Riverpod forbids.
  late AlarmSiren _siren;

  @override
  AlarmState build() {
    _siren = ref.read(alarmSirenProvider);
    ref.onDispose(_siren.stop);

    // Listen to the voyage, not to `boundaryStatusProvider`.
    //
    // `boundaryStatusProvider` is a computed provider: it is only recalculated
    // when something reads it, so subscribing to it would make the alarm
    // depend on a widget happening to be on screen. `voyageProvider` pushes on
    // every position fix, which is what a safety alarm must key off.
    // Evaluation itself reads the boundary, so the geometry is still shared.
    //
    // Not `fireImmediately`: that would run before `build` returns, and
    // `_evaluate` assigns to `state`. The first pass is done below instead.
    ref.listen(voyageProvider, (_, next) => _evaluate(next));

    return _evaluateFrom(const AlarmState.clear(), ref.read(voyageProvider));
  }

  void _evaluate(VoyageState voyage) {
    state = _evaluateFrom(state, voyage);
    _alertIfEscalated();
  }

  /// Pure: given the previous alarm state, produce the next one.
  ///
  /// Kept free of side effects so it can run during `build`, before `state`
  /// exists, as well as on every subsequent position update.
  AlarmState _evaluateFrom(AlarmState previous, VoyageState voyage) {
    final boundary = computeBoundaryStatus(voyage);

    // Two ways to be in breach: past the international line, or inside a
    // protected area. Both are `breached`; neither can be reasoned away.
    final breached =
        boundary.hasCrossed ||
        GeoMath.isPointInPolygon(voyage.position, DemoGeo.marineProtectedArea);

    final level = _levelFor(
      breached: breached,
      approaching: boundary.isApproaching,
      minutes: boundary.minutesToBreach,
    );

    // A dismissal only covers the level it was given for. If conditions worsen,
    // the alarm re-arms by itself — the user cannot silence the boundary.
    final acknowledged = level == AlarmLevel.none
        ? AlarmLevel.none
        : previous.acknowledgedLevel;

    return previous.copyWith(
      level: level,
      acknowledgedLevel: acknowledged,
      boundaryName: boundary.name,
      distanceKm: boundary.distanceKm,
      minutesToBreach: boundary.minutesToBreach,
      clearMinutes: boundary.minutesToBreach == null,
    );
  }

  static AlarmLevel _levelFor({
    required bool breached,
    required bool approaching,
    required int? minutes,
  }) {
    if (breached) return AlarmLevel.breached;
    if (!approaching || minutes == null) return AlarmLevel.none;
    if (minutes <= AlarmLevel.critical.minutesThreshold!) return AlarmLevel.critical;
    if (minutes <= AlarmLevel.warning.minutesThreshold!) return AlarmLevel.warning;
    if (minutes <= AlarmLevel.advisory.minutesThreshold!) return AlarmLevel.advisory;
    return AlarmLevel.none;
  }

  /// Sound and vibrate only on the way up.
  ///
  /// Re-firing on every tick would train the crew to ignore it, which is worse
  /// than not alarming at all.
  void _alertIfEscalated() {
    final level = state.level;

    if (!level.isActive) {
      _lastSounded = AlarmLevel.none;
      _siren.stop();
      return;
    }
    if (!level.isHigherThan(_lastSounded)) return;

    _lastSounded = level;
    _vibrate(level);
    if (level.soundsSiren) _playSiren(level);
  }

  Future<void> _playSiren(AlarmLevel level) async {
    // Looping only for the levels that take over the screen: a warning should
    // sound once, a critical alarm should not stop until it is acknowledged.
    await _siren.start(loop: level.takesOverScreen);
  }

  Future<void> _vibrate(AlarmLevel level) async {
    try {
      if (level.takesOverScreen) {
        for (var i = 0; i < 3; i++) {
          await HapticFeedback.heavyImpact();
          await Future<void>.delayed(const Duration(milliseconds: 180));
        }
      } else {
        await HapticFeedback.mediumImpact();
      }
    } on Object {
      // Haptics are unavailable on some devices. Not worth a crash.
    }
  }

  /// Dismiss the current alarm. It re-arms automatically if the level rises.
  void acknowledge() {
    _siren.stop();
    state = state.copyWith(acknowledgedLevel: state.level);
  }

  /// Full reset — used when a trip ends or the demo track is rewound.
  void reset() {
    _siren.stop();
    _lastSounded = AlarmLevel.none;
    state = const AlarmState.clear();
  }
}

final alarmProvider = NotifierProvider<AlarmController, AlarmState>(
  AlarmController.new,
);
