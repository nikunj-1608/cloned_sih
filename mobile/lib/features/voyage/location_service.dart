import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/geo/geo_math.dart';
import '../map/demo_geo.dart';

/// One position report.
class Fix {
  const Fix({
    required this.position,
    required this.headingDeg,
    required this.speedKnots,
  });

  final LatLng position;
  final double headingDeg;
  final double speedKnots;
}

/// Where fixes come from.
///
/// The seam that lets the boundary alarm be demonstrated on land. Both
/// implementations emit the same [Fix] stream, so nothing downstream — the
/// geofence maths, the alarm, the UI — knows or cares which one is running.
abstract interface class LocationService {
  Stream<Fix> fixes();
  Future<bool> ensurePermission();
  void dispose();
}

/// The real receiver. Used at sea.
class GeolocatorLocationService implements LocationService {
  StreamSubscription<Position>? _subscription;

  @override
  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Stream<Fix> fixes() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        // A boat at 6 knots covers 10 m in ~3 seconds. Any tighter and the
        // receiver burns battery that has to last the whole trip.
        distanceFilter: 10,
      ),
    ).map(
      (p) => Fix(
        position: LatLng(p.latitude, p.longitude),
        // `heading` is -1 when the device cannot determine course.
        headingDeg: p.heading >= 0 ? p.heading : 0,
        speedKnots: p.speed / 0.514444,
      ),
    );
  }

  @override
  void dispose() => _subscription?.cancel();
}

/// A scripted track out of Rameswaram toward the IMBL.
///
/// This is how the alarm gets filmed. A live receiver on dry land will not
/// approach a maritime boundary, and mocking GPS at the OS level is fragile
/// mid-take. See blocker #6 in `PROJECT_STATE.md`.
class ScriptedLocationService implements LocationService {
  ScriptedLocationService({
    this.start = DemoGeo.homePort,
    this.headingDeg = 118,
    this.speedKnots = 6.5,
    this.compression = 120,
  });

  final LatLng start;
  final double headingDeg;
  final double speedKnots;

  /// Seconds of sailing simulated per real second, so the run out to the
  /// boundary fits inside a demo rather than taking two hours.
  final int compression;

  Timer? _timer;
  StreamController<Fix>? _controller;

  @override
  Future<bool> ensurePermission() async => true;

  @override
  Stream<Fix> fixes() {
    _controller?.close();
    final controller = StreamController<Fix>.broadcast();
    _controller = controller;

    var position = start;
    final stepKm = speedKnots * 1.852 / 3600 * compression;

    controller.add(
      Fix(position: position, headingDeg: headingDeg, speedKnots: speedKnots),
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      position = GeoMath.destination(position, headingDeg, stepKm);
      if (!controller.isClosed) {
        controller.add(
          Fix(position: position, headingDeg: headingDeg, speedKnots: speedKnots),
        );
      }
    });

    controller.onCancel = () {
      _timer?.cancel();
      _timer = null;
    };
    return controller.stream;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.close();
  }
}
