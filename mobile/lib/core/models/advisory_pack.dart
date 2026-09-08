import 'dart:convert';

import 'package:latlong2/latlong.dart';

/// Everything the app needs to survive a trip with no network.
///
/// Downloaded in one request at port (`GET /v1/advisory-pack`) and written to
/// `sqflite`. At sea this is the only data there is, so [fetchedAt] and
/// [validUntil] are load-bearing: the UI degrades its confidence as the pack
/// ages rather than presenting day-old wave heights as current.
class AdvisoryPack {
  const AdvisoryPack({
    required this.generatedAt,
    required this.validUntil,
    required this.fetchedAt,
    required this.centre,
    required this.waveHeightM,
    required this.windSpeedKmh,
    required this.seaSurfaceTempC,
    required this.severity,
    required this.summary,
    required this.summaryTa,
    required this.boundaries,
    required this.fishingZones,
    required this.source,
  });

  final DateTime generatedAt;
  final DateTime validUntil;

  /// When this device actually received the pack. Distinct from [generatedAt]:
  /// a pack read from cache was generated hours before it is read.
  final DateTime fetchedAt;

  final LatLng centre;
  final double? waveHeightM;
  final double? windSpeedKmh;
  final double? seaSurfaceTempC;
  final String severity;
  final String summary;
  final String? summaryTa;

  /// Raw GeoJSON, handed straight to `flutter_map` and to the geofence engine.
  final Map<String, dynamic> boundaries;
  final Map<String, dynamic> fishingZones;

  final AdvisorySource source;

  Duration get age => DateTime.now().difference(generatedAt);
  bool get isExpired => DateTime.now().isAfter(validUntil);

  /// Mirrors the backend's `Freshness` enum so both ends agree on the wording.
  String get freshness {
    if (isExpired) return 'stale';
    final hours = age.inHours;
    if (hours < 1) return 'live';
    if (hours < 6) return 'recent';
    return 'stale';
  }

  String get ageLabel {
    final minutes = age.inMinutes;
    if (minutes < 1) return 'just now';
    if (minutes < 60) return '$minutes min ago';
    if (age.inHours < 24) return '${age.inHours} hr ago';
    return '${age.inDays} days ago';
  }

  factory AdvisoryPack.fromJson(
    Map<String, dynamic> json, {
    required AdvisorySource source,
    DateTime? fetchedAt,
  }) {
    final conditions = json['conditions'] as Map<String, dynamic>? ?? const {};
    final centre = json['centre'] as Map<String, dynamic>? ?? const {};

    return AdvisoryPack(
      generatedAt: DateTime.parse(json['generated_at'] as String).toLocal(),
      validUntil: DateTime.parse(json['valid_until'] as String).toLocal(),
      fetchedAt: fetchedAt ?? DateTime.now(),
      centre: LatLng(
        (centre['lat'] as num?)?.toDouble() ?? 0,
        (centre['lon'] as num?)?.toDouble() ?? 0,
      ),
      waveHeightM: (conditions['wave_height_m'] as num?)?.toDouble(),
      windSpeedKmh: (conditions['wind_speed_kmh'] as num?)?.toDouble(),
      seaSurfaceTempC: (conditions['sea_surface_temp_c'] as num?)?.toDouble(),
      severity: conditions['severity'] as String? ?? 'info',
      summary: conditions['summary'] as String? ?? 'No advisory available.',
      summaryTa: conditions['summary_ta'] as String?,
      boundaries: (json['boundaries'] as Map<String, dynamic>?) ?? const {},
      fishingZones: (json['fishing_zones'] as Map<String, dynamic>?) ?? const {},
      source: source,
    );
  }

  String encode() => jsonEncode({
    'generated_at': generatedAt.toUtc().toIso8601String(),
    'valid_until': validUntil.toUtc().toIso8601String(),
    'centre': {'lat': centre.latitude, 'lon': centre.longitude},
    'conditions': {
      'wave_height_m': waveHeightM,
      'wind_speed_kmh': windSpeedKmh,
      'sea_surface_temp_c': seaSurfaceTempC,
      'severity': severity,
      'summary': summary,
      'summary_ta': summaryTa,
    },
    'boundaries': boundaries,
    'fishing_zones': fishingZones,
  });
}

/// Where a pack came from. The UI says so plainly — a fisherman should always
/// know whether they are looking at fresh data or yesterday's.
enum AdvisorySource { network, cache }
