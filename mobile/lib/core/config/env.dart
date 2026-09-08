import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to the values in `mobile/.env`.
///
/// Nothing in the app reads `dotenv` directly. Every key is funnelled through
/// here so that a missing or malformed value fails in one obvious place rather
/// than as a null somewhere deep in a network call.
abstract final class Env {
  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get apiBaseUrl =>
      _read('API_BASE_URL', fallback: 'http://10.0.2.2:8000');

  static String get mapTileUrl => _read(
    'MAP_TILE_URL',
    fallback: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  static String get mapAttribution =>
      _read('MAP_ATTRIBUTION', fallback: '© OpenStreetMap contributors');

  /// Replays a scripted GPS track instead of reading the device receiver, so
  /// the boundary alarm can be demonstrated on land. See `PROJECT_STATE.md`.
  static bool get demoMode => _read('DEMO_MODE', fallback: 'true') == 'true';

  static String _read(String key, {required String fallback}) {
    // `dotenv` throws rather than returning null when `load()` was never
    // called, which happens in widget tests and on any handset where the
    // developer skipped `cp .env.example .env`. Fall back instead of crashing.
    if (!dotenv.isInitialized) return fallback;

    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) return fallback;
    return value;
  }
}
