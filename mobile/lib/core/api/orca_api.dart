import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/env.dart';
import '../models/advisory_pack.dart';

/// Thrown when the backend cannot be reached or answers badly.
///
/// Callers are expected to catch this and fall back to cache — at sea it is the
/// normal case, not an exceptional one.
class OrcaApiException implements Exception {
  const OrcaApiException(this.message);
  final String message;

  @override
  String toString() => 'OrcaApiException: $message';
}

/// Thin client over the FastAPI backend.
///
/// Every call is bounded by a timeout. Nothing here retries: on a boat, a
/// failed request means there is no network, and hammering it drains a battery
/// that may need to last days.
class OrcaApi {
  OrcaApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? Env.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  static const Duration _timeout = Duration(seconds: 8);

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    try {
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        throw OrcaApiException('${response.statusCode} from $path');
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on OrcaApiException {
      rethrow;
    } on SocketException catch (e) {
      throw OrcaApiException('No network: ${e.message}');
    } on Object catch (e) {
      throw OrcaApiException('$path failed: $e');
    }
  }

  /// Download the offline pack for a position. Issued at port, over a marginal
  /// harbour connection, often while the boat is already casting off.
  Future<AdvisoryPack> fetchAdvisoryPack(LatLng at) async {
    final json = await _get('/v1/advisory-pack', {
      'lat': at.latitude.toStringAsFixed(4),
      'lon': at.longitude.toStringAsFixed(4),
    });
    return AdvisoryPack.fromJson(json, source: AdvisorySource.network);
  }

  /// Ask the assistant. Phase 4 swaps the backend's engine behind this;
  /// the request and response shapes do not change.
  Future<Map<String, dynamic>> chat({
    required String message,
    LatLng? position,
    String language = 'en',
  }) async {
    final uri = Uri.parse('$_baseUrl/v1/chat');
    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'language': language,
              if (position != null)
                'position': {
                  'lat': position.latitude,
                  'lon': position.longitude,
                },
            }),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw OrcaApiException('${response.statusCode} from /v1/chat');
      }
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } on OrcaApiException {
      rethrow;
    } on Object catch (e) {
      throw OrcaApiException('/v1/chat failed: $e');
    }
  }

  void dispose() => _client.close();
}
