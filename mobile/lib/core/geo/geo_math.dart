import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Dependency-free geodesy for the offline safety kernel.
///
/// This deliberately does not use a third-party geometry package. Everything
/// here runs on-device with no network and no model in the loop, and it decides
/// whether a boundary alarm fires — so it stays small, deterministic and
/// unit-testable. See the note in `Tasks.md` on `turf`.
abstract final class GeoMath {
  static const double _earthRadiusKm = 6371.0088;

  static double _rad(double deg) => deg * math.pi / 180;

  /// Great-circle distance in kilometres.
  static double haversineKm(LatLng a, LatLng b) {
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);

    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * _earthRadiusKm * math.asin(math.min(1, math.sqrt(h)));
  }

  /// Shortest distance from [p] to the polyline [line], in kilometres.
  ///
  /// Segments are short relative to the earth's curvature at the scale we care
  /// about (tens of kilometres), so each one is flattened with an
  /// equirectangular projection before the perpendicular is taken.
  static double distanceToPolylineKm(LatLng p, List<LatLng> line) =>
      nearestSegment(p, line).distanceKm;

  /// The closest segment of [line] to [p], and how far away it is.
  ///
  /// The index is needed to decide which *side* of the boundary a vessel is
  /// on — see [sideOfPolyline].
  static ({double distanceKm, int segmentIndex}) nearestSegment(
    LatLng p,
    List<LatLng> line,
  ) {
    if (line.isEmpty) return (distanceKm: double.infinity, segmentIndex: -1);
    if (line.length == 1) {
      return (distanceKm: haversineKm(p, line.first), segmentIndex: 0);
    }

    var best = double.infinity;
    var bestIndex = 0;
    for (var i = 0; i < line.length - 1; i++) {
      final d = _distanceToSegmentKm(p, line[i], line[i + 1]);
      if (d < best) {
        best = d;
        bestIndex = i;
      }
    }
    return (distanceKm: best, segmentIndex: bestIndex);
  }

  /// Which side of [line] the point [p] falls on: `1`, `-1`, or `0` on the line.
  ///
  /// Uses the sign of the cross product against the nearest segment. The
  /// absolute value is meaningless — only the comparison between two points
  /// matters, which is how [hasCrossed] detects a breach.
  static int sideOfPolyline(LatLng p, List<LatLng> line) {
    if (line.length < 2) return 0;

    final index = nearestSegment(p, line).segmentIndex;
    final a = line[index];
    final b = line[index + 1];

    final cross =
        (b.longitude - a.longitude) * (p.latitude - a.latitude) -
        (b.latitude - a.latitude) * (p.longitude - a.longitude);
    if (cross > 0) return 1;
    if (cross < 0) return -1;
    return 0;
  }

  /// Whether [p] has ended up on the far side of [line] from [reference].
  ///
  /// > [!IMPORTANT]
  /// > This is what makes a crossing detectable at all. Distance alone cannot
  /// > do it: once a vessel is past the boundary the distance starts growing
  /// > again, so a purely distance-driven alarm falls silent at exactly the
  /// > moment it matters most.
  static bool hasCrossed(LatLng p, List<LatLng> line, {required LatLng reference}) {
    final home = sideOfPolyline(reference, line);
    final here = sideOfPolyline(p, line);
    if (home == 0 || here == 0) return false;
    return home != here;
  }

  static double _distanceToSegmentKm(LatLng p, LatLng a, LatLng b) {
    // Project onto a local plane centred on `a`, scaling longitude by the
    // cosine of latitude so that one unit is one kilometre on both axes.
    final latScale = _earthRadiusKm * math.pi / 180;
    final lonScale = latScale * math.cos(_rad(a.latitude));

    final px = (p.longitude - a.longitude) * lonScale;
    final py = (p.latitude - a.latitude) * latScale;
    final bx = (b.longitude - a.longitude) * lonScale;
    final by = (b.latitude - a.latitude) * latScale;

    final segLenSq = bx * bx + by * by;
    if (segLenSq == 0) return math.sqrt(px * px + py * py);

    // Clamp so the nearest point stays on the segment, not its infinite line.
    final t = ((px * bx + py * by) / segLenSq).clamp(0.0, 1.0);
    final dx = px - bx * t;
    final dy = py - by * t;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Ray-casting point-in-polygon test. [polygon] is treated as closed.
  static bool isPointInPolygon(LatLng p, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final yi = polygon[i].latitude;
      final xi = polygon[i].longitude;
      final yj = polygon[j].latitude;
      final xj = polygon[j].longitude;

      final crosses =
          (yi > p.latitude) != (yj > p.latitude) &&
          p.longitude < (xj - xi) * (p.latitude - yi) / (yj - yi) + xi;
      if (crosses) inside = !inside;
    }
    return inside;
  }

  /// Initial bearing from [a] to [b], in degrees clockwise from true north.
  static double bearingDeg(LatLng a, LatLng b) {
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final dLon = _rad(b.longitude - a.longitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// The point reached by travelling [distanceKm] from [from] along [bearing].
  static LatLng destination(LatLng from, double bearing, double distanceKm) {
    final angular = distanceKm / _earthRadiusKm;
    final brg = _rad(bearing);
    final lat1 = _rad(from.latitude);
    final lon1 = _rad(from.longitude);

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(angular) +
          math.cos(lat1) * math.sin(angular) * math.cos(brg),
    );
    final lon2 =
        lon1 +
        math.atan2(
          math.sin(brg) * math.sin(angular) * math.cos(lat1),
          math.cos(angular) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(lat2 * 180 / math.pi, lon2 * 180 / math.pi);
  }

  /// Smallest absolute difference between two bearings, in degrees (0–180).
  static double bearingDeltaDeg(double a, double b) {
    final diff = (a - b).abs() % 360;
    return diff > 180 ? 360 - diff : diff;
  }
}
