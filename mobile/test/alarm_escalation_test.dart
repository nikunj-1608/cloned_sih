import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:orca/core/geo/geo_math.dart';
import 'package:orca/features/alarm/alarm_controller.dart';
import 'package:orca/features/alarm/alarm_siren.dart';
import 'package:orca/features/alarm/alarm_state.dart';
import 'package:orca/features/map/demo_geo.dart';
import 'package:orca/features/voyage/location_service.dart';
import 'package:orca/features/voyage/voyage_controller.dart';

/// A location source the test drives by hand, so escalation can be checked
/// without waiting on a timer.
class FakeLocationService implements LocationService {
  final _controller = StreamController<Fix>.broadcast();

  void emit(LatLng position, {double heading = 118, double knots = 6.5}) {
    _controller.add(
      Fix(position: position, headingDeg: heading, speedKnots: knots),
    );
  }

  @override
  Future<bool> ensurePermission() async => true;

  @override
  Stream<Fix> fixes() => _controller.stream;

  @override
  void dispose() => _controller.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLocationService location;
  late SilentAlarmSiren siren;
  late ProviderContainer container;

  setUp(() {
    location = FakeLocationService();
    siren = SilentAlarmSiren();
    container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(location),
        alarmSirenProvider.overrideWithValue(siren),
      ],
    );
    // Keep the alarm alive for the whole test, as the shell does.
    container.listen(alarmProvider, (_, _) {});
  });

  tearDown(() {
    container.dispose();
    location.dispose();
  });

  /// A position [km] along the demo heading out of Rameswaram.
  LatLng outbound(double km) =>
      GeoMath.destination(DemoGeo.homePort, 118, km);

  Future<void> sailTo(double km) async {
    location.emit(outbound(km));
    await Future<void>.delayed(Duration.zero);
  }

  test('alarm is silent at the jetty', () {
    expect(container.read(alarmProvider).level, AlarmLevel.none);
    expect(container.read(alarmProvider).isRinging, isFalse);
  });

  test('escalates as the vessel closes on the boundary', () async {
    await container.read(voyageProvider.notifier).startVoyage();

    final observed = <double, AlarmLevel>{};
    for (final km in [0.0, 4.0, 8.0, 11.0, 12.5, 13.5, 14.4, 14.9, 15.5]) {
      await sailTo(km);
      observed[km] = container.read(alarmProvider).level;
    }

    // Levels must never go backwards as the boundary gets closer.
    final sequence = observed.values.toList();
    for (var i = 1; i < sequence.length; i++) {
      expect(
        sequence[i].index,
        greaterThanOrEqualTo(sequence[i - 1].index),
        reason: 'alarm de-escalated while still closing: $observed',
      );
    }

    // And it must reach a screen-takeover level, ending in a breach once the
    // vessel is past the line.
    expect(
      sequence.last,
      AlarmLevel.breached,
      reason: 'crossing the line did not register as a breach: $observed',
    );
    expect(observed[14.4]!.takesOverScreen, isTrue);
  });

  test('the alarm keeps sounding after the line is crossed', () async {
    // The regression that matters most. Past the boundary the distance starts
    // growing again, so a distance-only alarm falls silent exactly when the
    // vessel is in foreign waters.
    await container.read(voyageProvider.notifier).startVoyage();

    await sailTo(15.5);
    expect(container.read(alarmProvider).level, AlarmLevel.breached);

    // Still wrong-side, and now well past the line.
    await sailTo(20.0);
    final far = container.read(alarmProvider);
    expect(far.level, AlarmLevel.breached);
    expect(far.isRinging, isTrue);
    expect(far.shouldTakeOverScreen, isTrue);
  });

  test('dismissing a lower level does not silence a higher one', () async {
    await container.read(voyageProvider.notifier).startVoyage();

    await sailTo(8.0);
    final early = container.read(alarmProvider);
    expect(early.level.isActive, isTrue);

    container.read(alarmProvider.notifier).acknowledge();
    expect(container.read(alarmProvider).isRinging, isFalse);

    // Keep going. The alarm must come back on its own.
    await sailTo(14.9);
    final later = container.read(alarmProvider);
    expect(later.level.isHigherThan(early.level), isTrue);
    expect(
      later.isRinging,
      isTrue,
      reason: 'a dismissed advisory silenced the critical alarm',
    );
  });

  test('alarm clears when the vessel turns away', () async {
    await container.read(voyageProvider.notifier).startVoyage();

    await sailTo(12.0);
    expect(container.read(alarmProvider).level.isActive, isTrue);

    // Turn 180 degrees: the boundary is no longer being approached.
    location.emit(outbound(12.0), heading: 298);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(alarmProvider).level, AlarmLevel.none);
  });

  test('the siren sounds once per escalation, not on every fix', () async {
    // Re-firing on every tick would train the crew to ignore it, which is
    // worse than not alarming at all.
    await container.read(voyageProvider.notifier).startVoyage();

    await sailTo(12.5);
    final afterFirst = siren.startCount;
    expect(afterFirst, greaterThan(0));

    // Several more fixes at the same alarm level must not re-trigger it.
    await sailTo(12.6);
    await sailTo(12.7);
    expect(siren.startCount, afterFirst);

    // Escalating does.
    await sailTo(14.4);
    expect(siren.startCount, greaterThan(afterFirst));
  });

  test('a stationary vessel does not alarm', () async {
    await container.read(voyageProvider.notifier).startVoyage();
    location.emit(outbound(14.9), knots: 0);
    await Future<void>.delayed(Duration.zero);

    // Close to the line, but not moving toward it — there is no time to breach.
    expect(container.read(alarmProvider).minutesToBreach, isNull);
    expect(container.read(alarmProvider).level, AlarmLevel.none);
  });
}
