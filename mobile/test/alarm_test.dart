import 'package:flutter_test/flutter_test.dart';
import 'package:orca/features/alarm/alarm_state.dart';

/// The escalation rules decide whether a boundary alarm reaches the crew, so
/// they are tested directly rather than only through the UI.
void main() {
  group('AlarmLevel ordering', () {
    test('escalates in severity order', () {
      expect(AlarmLevel.advisory.isHigherThan(AlarmLevel.none), isTrue);
      expect(AlarmLevel.warning.isHigherThan(AlarmLevel.advisory), isTrue);
      expect(AlarmLevel.critical.isHigherThan(AlarmLevel.warning), isTrue);
      expect(AlarmLevel.breached.isHigherThan(AlarmLevel.critical), isTrue);
    });

    test('does not treat a level as higher than itself', () {
      for (final level in AlarmLevel.values) {
        expect(level.isHigherThan(level), isFalse);
      }
    });

    test('only the top two levels take over the screen', () {
      // An advisory 45 minutes out must not blank the chart someone is
      // steering by.
      expect(AlarmLevel.advisory.takesOverScreen, isFalse);
      expect(AlarmLevel.warning.takesOverScreen, isFalse);
      expect(AlarmLevel.critical.takesOverScreen, isTrue);
      expect(AlarmLevel.breached.takesOverScreen, isTrue);
    });

    test('thresholds descend with severity', () {
      expect(AlarmLevel.advisory.minutesThreshold, 45);
      expect(AlarmLevel.warning.minutesThreshold, 15);
      expect(AlarmLevel.critical.minutesThreshold, 5);
      expect(AlarmLevel.breached.minutesThreshold, 0);
    });

    test('every active level carries both scripts', () {
      for (final level in AlarmLevel.values) {
        expect(level.title.en, isNotEmpty);
        expect(level.title.ta, isNotEmpty);
      }
    });
  });

  group('AlarmState ringing', () {
    AlarmState state({
      required AlarmLevel level,
      AlarmLevel acknowledged = AlarmLevel.none,
      int? minutes,
    }) => AlarmState(
      level: level,
      acknowledgedLevel: acknowledged,
      boundaryName: 'IMBL',
      distanceKm: 4.2,
      minutesToBreach: minutes,
    );

    test('a clear state never rings', () {
      expect(const AlarmState.clear().isRinging, isFalse);
      expect(const AlarmState.clear().shouldTakeOverScreen, isFalse);
    });

    test('rings when a level is reached and not yet acknowledged', () {
      expect(state(level: AlarmLevel.warning).isRinging, isTrue);
    });

    test('goes quiet once acknowledged at the same level', () {
      final acknowledged = state(
        level: AlarmLevel.warning,
        acknowledged: AlarmLevel.warning,
      );
      expect(acknowledged.isRinging, isFalse);
    });

    test('re-arms by itself when the situation worsens', () {
      // The crucial property: dismissing a warning must not silence the
      // critical alarm that follows it.
      final worsened = state(
        level: AlarmLevel.critical,
        acknowledged: AlarmLevel.warning,
      );
      expect(worsened.isRinging, isTrue);
      expect(worsened.shouldTakeOverScreen, isTrue);
    });

    test('a dismissed critical alarm still rings once breached', () {
      final breached = state(
        level: AlarmLevel.breached,
        acknowledged: AlarmLevel.critical,
      );
      expect(breached.isRinging, isTrue);
    });

    test('a dismissed advisory does not take over the screen', () {
      final dismissed = state(
        level: AlarmLevel.advisory,
        acknowledged: AlarmLevel.advisory,
      );
      expect(dismissed.shouldTakeOverScreen, isFalse);
    });
  });

  group('AlarmState time label', () {
    AlarmState withMinutes(int? minutes) => AlarmState(
      level: AlarmLevel.warning,
      acknowledgedLevel: AlarmLevel.none,
      boundaryName: 'IMBL',
      distanceKm: 12.4,
      minutesToBreach: minutes,
    );

    test('falls back to distance when not closing', () {
      expect(withMinutes(null).timeLabel, '12.4 km away');
    });

    test('reads in minutes under an hour', () {
      expect(withMinutes(12).timeLabel, '12 min');
    });

    test('reads in hours and minutes above an hour', () {
      expect(withMinutes(95).timeLabel, '1 hr 35 min');
    });

    test('reports a crossing rather than a negative countdown', () {
      expect(withMinutes(0).timeLabel, 'Crossed');
      expect(withMinutes(-3).timeLabel, 'Crossed');
    });
  });
}
