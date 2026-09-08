import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orca/core/models/advisory_pack.dart';

/// The advisory pack is what the app runs on once the network is gone, so its
/// parsing and its ageing rules are tested independently of any UI.
void main() {
  Map<String, dynamic> payload({
    required DateTime generatedAt,
    Duration validity = const Duration(hours: 24),
  }) => {
    'generated_at': generatedAt.toUtc().toIso8601String(),
    'valid_until': generatedAt.add(validity).toUtc().toIso8601String(),
    'centre': {'lat': 9.2876, 'lon': 79.3129},
    'conditions': {
      'wave_height_m': 1.1,
      'wind_speed_kmh': 28.5,
      'sea_surface_temp_c': 29.8,
      'severity': 'safe',
      'summary': 'Calm — 1.1 m waves.',
      'summary_ta': 'கடல் அமைதியாக உள்ளது.',
    },
    'boundaries': {'type': 'FeatureCollection', 'features': []},
    'fishing_zones': {'type': 'FeatureCollection', 'features': []},
  };

  group('parsing', () {
    test('reads the fields the app depends on', () {
      final pack = AdvisoryPack.fromJson(
        payload(generatedAt: DateTime.now()),
        source: AdvisorySource.network,
      );

      expect(pack.waveHeightM, 1.1);
      expect(pack.windSpeedKmh, 28.5);
      expect(pack.severity, 'safe');
      expect(pack.summaryTa, isNotNull);
      expect(pack.centre.latitude, closeTo(9.2876, 1e-6));
    });

    test('survives a response missing optional fields', () {
      final sparse = payload(generatedAt: DateTime.now())
        ..['conditions'] = <String, dynamic>{};
      final pack = AdvisoryPack.fromJson(sparse, source: AdvisorySource.cache);

      expect(pack.waveHeightM, isNull);
      expect(pack.severity, 'info');
      expect(pack.summary, isNotEmpty);
    });

    test('round-trips through the cache encoding', () {
      final original = AdvisoryPack.fromJson(
        payload(generatedAt: DateTime.now()),
        source: AdvisorySource.network,
      );
      final restored = AdvisoryPack.fromJson(
        jsonDecode(original.encode()) as Map<String, dynamic>,
        source: AdvisorySource.cache,
      );

      expect(restored.waveHeightM, original.waveHeightM);
      expect(restored.severity, original.severity);
      expect(restored.summaryTa, original.summaryTa);
      expect(restored.source, AdvisorySource.cache);
    });
  });

  group('ageing', () {
    AdvisoryPack aged(Duration age) => AdvisoryPack.fromJson(
      payload(generatedAt: DateTime.now().subtract(age)),
      source: AdvisorySource.cache,
    );

    test('a fresh pack reads as live', () {
      expect(aged(const Duration(minutes: 10)).freshness, 'live');
    });

    test('confidence degrades with age', () {
      expect(aged(const Duration(hours: 3)).freshness, 'recent');
      expect(aged(const Duration(hours: 9)).freshness, 'stale');
    });

    test('expires past its validity window', () {
      final old = aged(const Duration(hours: 30));
      expect(old.isExpired, isTrue);
      expect(old.freshness, 'stale');
    });

    test('labels its age in human terms', () {
      expect(aged(const Duration(minutes: 25)).ageLabel, '25 min ago');
      expect(aged(const Duration(hours: 5)).ageLabel, '5 hr ago');
      expect(aged(const Duration(days: 2)).ageLabel, '2 days ago');
    });
  });
}
