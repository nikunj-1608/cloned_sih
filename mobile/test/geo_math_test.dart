import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:orca/core/geo/geo_math.dart';
import 'package:orca/features/map/demo_geo.dart';

/// The offline safety kernel decides whether a boundary alarm fires, so its
/// geometry is tested directly rather than only through the UI.
void main() {
  group('haversineKm', () {
    test('is zero for a point against itself', () {
      expect(GeoMath.haversineKm(DemoGeo.homePort, DemoGeo.homePort), 0);
    });

    test('matches a known separation', () {
      // Rameswaram to Katchatheevu is roughly 27 km.
      const katchatheevu = LatLng(9.3833, 79.5167);
      final km = GeoMath.haversineKm(DemoGeo.homePort, katchatheevu);
      expect(km, closeTo(27, 3));
    });

    test('is symmetric', () {
      const a = LatLng(9.0, 79.0);
      const b = LatLng(9.5, 79.6);
      expect(
        GeoMath.haversineKm(a, b),
        closeTo(GeoMath.haversineKm(b, a), 1e-9),
      );
    });
  });

  group('distanceToPolylineKm', () {
    test('is zero on a vertex', () {
      expect(
        GeoMath.distanceToPolylineKm(DemoGeo.imbl[3], DemoGeo.imbl),
        closeTo(0, 1e-6),
      );
    });

    test('measures perpendicular distance, not vertex distance', () {
      // A point beside the midpoint of a segment is closer to the segment
      // than to either end. This is the case a naive nearest-vertex
      // implementation gets wrong, and the one that matters at sea.
      const line = [LatLng(9.0, 79.0), LatLng(9.0, 80.0)];
      const beside = LatLng(9.1, 79.5);

      final toLine = GeoMath.distanceToPolylineKm(beside, line);
      final toNearestVertex = GeoMath.haversineKm(beside, line.first);

      expect(toLine, closeTo(11.1, 0.5));
      expect(toLine, lessThan(toNearestVertex));
    });

    test('never returns a negative distance', () {
      for (final point in [
        DemoGeo.homePort,
        const LatLng(8.0, 78.0),
        const LatLng(11.0, 81.0),
      ]) {
        expect(GeoMath.distanceToPolylineKm(point, DemoGeo.imbl), greaterThanOrEqualTo(0));
      }
    });
  });

  group('isPointInPolygon', () {
    const square = [
      LatLng(9.0, 79.0),
      LatLng(9.0, 79.5),
      LatLng(9.5, 79.5),
      LatLng(9.5, 79.0),
    ];

    test('accepts an interior point', () {
      expect(GeoMath.isPointInPolygon(const LatLng(9.25, 79.25), square), isTrue);
    });

    test('rejects an exterior point', () {
      expect(GeoMath.isPointInPolygon(const LatLng(9.25, 79.9), square), isFalse);
    });

    test('rejects degenerate polygons instead of throwing', () {
      expect(GeoMath.isPointInPolygon(const LatLng(9.25, 79.25), const []), isFalse);
    });
  });

  group('bearing and projection', () {
    test('due east is 90 degrees', () {
      const from = LatLng(9.0, 79.0);
      const to = LatLng(9.0, 79.5);
      expect(GeoMath.bearingDeg(from, to), closeTo(90, 0.5));
    });

    test('destination round-trips through haversine', () {
      const from = LatLng(9.2876, 79.3129);
      final to = GeoMath.destination(from, 118, 25);
      expect(GeoMath.haversineKm(from, to), closeTo(25, 0.05));
      expect(GeoMath.bearingDeg(from, to), closeTo(118, 0.5));
    });

    test('bearing delta wraps around north', () {
      expect(GeoMath.bearingDeltaDeg(350, 10), closeTo(20, 1e-9));
      expect(GeoMath.bearingDeltaDeg(10, 350), closeTo(20, 1e-9));
    });
  });
}
