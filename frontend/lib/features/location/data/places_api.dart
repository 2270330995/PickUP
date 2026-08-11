import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'places_config.dart';
import 'resolved_address.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.label,
  });

  final String placeId;
  final String label;

  /// Normalizes `places/ChIJ...` or raw `ChIJ...` to the ID used in Place Details URLs.
  static String normalizePlaceId(String raw) {
    const prefix = 'places/';
    if (raw.startsWith(prefix)) {
      return raw.substring(prefix.length);
    }
    return raw;
  }
}

/// Client for Google Places API (New) autocomplete and place details.
///
/// Autocomplete runs against Google directly. On Flutter web, resolving a
/// selection is proxied through the PickUP backend because browser CORS blocks
/// the Place Details field-mask headers.
class PlacesApi {
  PlacesApi({Dio? dio, Dio? backendDio})
      : _dio = dio ?? Dio(_baseOptions),
        _backendDio = backendDio;

  static const _baseUrl = 'https://places.googleapis.com/v1';

  static final BaseOptions _baseOptions = BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  );

  final Dio _dio;
  final Dio? _backendDio;

  Future<List<PlaceSuggestion>> autocomplete({
    required String input,
    required String sessionToken,
  }) async {
    if (!isGooglePlacesConfigured || input.trim().length < 2) {
      return const [];
    }
    final res = await _dio.post<Map<String, dynamic>>(
      '/places:autocomplete',
      data: {
        'input': input.trim(),
        'sessionToken': sessionToken,
      },
      options: Options(
        headers: {
          'X-Goog-Api-Key': googlePlacesApiKey,
        },
      ),
    );
    final suggestions = res.data?['suggestions'] as List<dynamic>? ?? const [];
    return suggestions
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final prediction = item['placePrediction'] as Map<String, dynamic>?;
          if (prediction == null) return null;
          final placeResource = prediction['place'] as String?;
          var placeId = prediction['placeId'] as String?;
          placeId ??= placeResource;
          final text = prediction['text'] as Map<String, dynamic>?;
          final label = text?['text'] as String?;
          if (placeId == null || label == null) return null;
          return PlaceSuggestion(
            placeId: PlaceSuggestion.normalizePlaceId(placeId),
            label: label,
          );
        })
        .whereType<PlaceSuggestion>()
        .toList(growable: false);
  }

  Future<ResolvedAddress> resolveSuggestion({
    required PlaceSuggestion suggestion,
    required String sessionToken,
  }) async {
    if (kIsWeb && _backendDio != null) {
      return _resolveViaBackend(
        placeId: suggestion.placeId,
        query: suggestion.label,
        sessionToken: sessionToken,
      );
    }
    try {
      return await _fetchPlaceDetails(
        placeId: suggestion.placeId,
        sessionToken: sessionToken,
      );
    } catch (_) {
      return await _searchText(
        query: suggestion.label,
        sessionToken: sessionToken,
      );
    }
  }

  Future<ResolvedAddress> _resolveViaBackend({
    required String placeId,
    required String query,
    required String sessionToken,
  }) async {
    try {
      final res = await _backendDio!.post<Map<String, dynamic>>(
        '/places/resolve',
        data: {
          'placeId': placeId,
          'query': query,
          'sessionToken': sessionToken,
        },
      );
      final envelope = ApiResponse<ResolvedAddress>.fromJson(
        res.data!,
        (raw) {
          final json = raw as Map<String, dynamic>;
          return ResolvedAddress(
            formattedAddress: json['formattedAddress'] as String,
            lat: (json['lat'] as num).toDouble(),
            lng: (json['lng'] as num).toDouble(),
          );
        },
      );
      final data = envelope.data;
      if (data == null) {
        throw ApiException(
          statusCode: res.statusCode,
          code: 'EMPTY_RESPONSE',
          message: 'Server returned empty payload',
        );
      }
      return data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ResolvedAddress> _fetchPlaceDetails({
    required String placeId,
    required String sessionToken,
  }) async {
    if (!isGooglePlacesConfigured) {
      throw StateError('Google Places API key is not configured');
    }
    final normalizedId = PlaceSuggestion.normalizePlaceId(placeId);
    final res = await _dio.get<Map<String, dynamic>>(
      '/places/${Uri.encodeComponent(normalizedId)}',
      options: Options(
        headers: {
          'X-Goog-Api-Key': googlePlacesApiKey,
          'X-Goog-FieldMask': 'formattedAddress,location',
          'X-Goog-Session-Token': sessionToken,
        },
      ),
    );
    return _parsePlace(res.data);
  }

  Future<ResolvedAddress> _searchText({
    required String query,
    required String sessionToken,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/places:searchText',
      data: {
        'textQuery': query,
        'maxResultCount': 1,
      },
      options: Options(
        headers: {
          'X-Goog-Api-Key': googlePlacesApiKey,
          'X-Goog-FieldMask': 'places.formattedAddress,places.location',
          'X-Goog-Session-Token': sessionToken,
        },
      ),
    );
    final places = res.data?['places'] as List<dynamic>? ?? const [];
    if (places.isEmpty) {
      throw StateError('No place found for "$query"');
    }
    final first = places.first;
    if (first is! Map<String, dynamic>) {
      throw StateError('Unexpected searchText response');
    }
    return _parsePlace(first);
  }

  ResolvedAddress _parsePlace(Map<String, dynamic>? data) {
    if (data == null) {
      throw StateError('Empty place response');
    }
    final address = data['formattedAddress'] as String?;
    final location = data['location'] as Map<String, dynamic>?;
    final lat = (location?['latitude'] as num?)?.toDouble();
    final lng = (location?['longitude'] as num?)?.toDouble();
    if (address == null || lat == null || lng == null) {
      throw StateError('Place response missing address or coordinates');
    }
    return ResolvedAddress(formattedAddress: address, lat: lat, lng: lng);
  }
}

final placesApiProvider = Provider<PlacesApi>((ref) {
  return PlacesApi(backendDio: ref.watch(dioProvider));
});
