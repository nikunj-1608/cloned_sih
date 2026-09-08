import 'package:latlong2/latlong.dart';

/// Illustrative geometry for the Palk Strait pilot region.
///
/// > [!WARNING]
/// > These coordinates are hand-drawn for development and the prototype video.
/// > They are NOT survey-accurate and must never be used for navigation. In
/// > Phase 2 they are replaced by authoritative GeoJSON served from the backend
/// > and cached to `sqflite`. The shape of the data is the contract; the values
/// > are placeholders.
abstract final class DemoGeo {
  /// Rameswaram harbour — the pilot launch point.
  static const LatLng homePort = LatLng(9.2876, 79.3129);

  /// Approximate India–Sri Lanka International Maritime Boundary Line through
  /// the Palk Strait and into the Gulf of Mannar.
  static const List<LatLng> imbl = [
    LatLng(10.3000, 80.0500),
    LatLng(9.8500, 79.8500),
    LatLng(9.5500, 79.7000),
    LatLng(9.3900, 79.5500),
    LatLng(9.1000, 79.3500),
    LatLng(8.8500, 79.0500),
    LatLng(8.5000, 78.7500),
  ];

  /// Gulf of Mannar Marine National Park — an ecologically sensitive zone that
  /// fishing vessels must keep clear of.
  static const List<LatLng> marineProtectedArea = [
    LatLng(9.2200, 79.1000),
    LatLng(9.1600, 79.2400),
    LatLng(9.0400, 79.2000),
    LatLng(8.9800, 79.0400),
    LatLng(9.0900, 78.9400),
    LatLng(9.1900, 78.9800),
  ];

  /// Potential Fishing Zones for the current advisory window.
  static const List<PfzZone> potentialFishingZones = [
    PfzZone(
      name: 'PFZ North',
      confidence: 'High',
      polygon: [
        LatLng(9.5200, 79.3200),
        LatLng(9.5000, 79.4600),
        LatLng(9.3800, 79.4400),
        LatLng(9.4000, 79.3000),
      ],
    ),
    PfzZone(
      name: 'PFZ East',
      confidence: 'Medium',
      polygon: [
        LatLng(9.2600, 79.4400),
        LatLng(9.2400, 79.5400),
        LatLng(9.1400, 79.5200),
        LatLng(9.1600, 79.4200),
      ],
    ),
  ];
}

class PfzZone {
  const PfzZone({
    required this.name,
    required this.confidence,
    required this.polygon,
  });

  final String name;
  final String confidence;
  final List<LatLng> polygon;
}
