import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How the alarm makes noise.
///
/// A seam, for the same reason [LocationService] is one: the escalation logic
/// is safety-critical and must be testable without a platform plugin attached.
/// It also means a device with no audio route degrades to a silent visual
/// alarm rather than taking the app down.
abstract interface class AlarmSiren {
  Future<void> start({required bool loop});
  Future<void> stop();
  void dispose();
}

/// Plays the bundled siren asset. Works with the radio off.
class AudioAlarmSiren implements AlarmSiren {
  AudioPlayer? _player;

  @override
  Future<void> start({required bool loop}) async {
    try {
      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await player.setVolume(1);
      await player.play(AssetSource('audio/siren.wav'));
    } on Object catch (error) {
      // Muted, no audio route, or no plugin. The visual alarm and the haptics
      // still stand — never let this take the app down.
      debugPrint('ORCA: siren failed ($error)');
      _player = null;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player?.stop();
    } on Object {
      // Nothing useful to do if stopping fails.
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    _player = null;
  }
}

/// No-op siren, for tests and for platforms with no audio plugin.
class SilentAlarmSiren implements AlarmSiren {
  int startCount = 0;

  @override
  Future<void> start({required bool loop}) async => startCount++;

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

final alarmSirenProvider = Provider<AlarmSiren>((ref) {
  final siren = AudioAlarmSiren();
  ref.onDispose(siren.dispose);
  return siren;
});
