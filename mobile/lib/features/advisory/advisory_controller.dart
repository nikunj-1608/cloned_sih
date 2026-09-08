import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api/orca_api.dart';
import '../../core/models/advisory_pack.dart';
import '../../core/storage/advisory_cache.dart';

final orcaApiProvider = Provider<OrcaApi>((ref) {
  final api = OrcaApi();
  ref.onDispose(api.dispose);
  return api;
});

/// The on-device cache, or null where sqflite is unavailable (widget tests,
/// desktop). A missing cache costs offline persistence, not correctness.
final advisoryCacheProvider = FutureProvider<AdvisoryCache?>((ref) async {
  try {
    final cache = await AdvisoryCache.open();
    ref.onDispose(cache.close);
    return cache;
  } on Object catch (error) {
    debugPrint('ORCA: advisory cache unavailable ($error)');
    return null;
  }
});

/// Owns the advisory pack: fetch at port, read at sea.
///
/// The rule is that the app is never empty-handed. On startup it loads whatever
/// is cached, so the map and the sea state are on screen before any network
/// call is attempted. A download replaces that; a failed download leaves the
/// cached pack in place with its age shown honestly.
class AdvisoryController extends AsyncNotifier<AdvisoryPack?> {
  @override
  Future<AdvisoryPack?> build() async {
    final cache = await ref.watch(advisoryCacheProvider.future);
    return cache?.read();
  }

  /// Download a fresh pack for [at] and persist it.
  ///
  /// Never throws. On failure the previous pack is kept and [lastError] is set,
  /// because at sea a failed refresh is routine — not an error state worth
  /// blanking the screen for.
  Future<void> download(LatLng at) async {
    final previous = state.value;
    state = const AsyncValue<AdvisoryPack?>.loading();

    try {
      final pack = await ref.read(orcaApiProvider).fetchAdvisoryPack(at);
      final cache = await ref.read(advisoryCacheProvider.future);
      await cache?.save(pack);

      lastError = null;
      state = AsyncValue.data(pack);
    } on Object catch (error) {
      lastError = error is OrcaApiException
          ? 'Could not reach the server. Using saved data.'
          : 'Download failed. Using saved data.';
      state = AsyncValue.data(previous);
    }
  }

  /// Why the last download failed, or null. Surfaced as a quiet note rather
  /// than an error dialog.
  String? lastError;
}

final advisoryProvider =
    AsyncNotifierProvider<AdvisoryController, AdvisoryPack?>(
      AdvisoryController.new,
    );
