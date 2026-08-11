import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'trip_dtos.dart';
import 'trip_execution_dtos.dart';

class TripApi {
  TripApi(this._dio);
  final Dio _dio;

  Future<TripResponse> get(String tripId) =>
      _call(() => _dio.get<Map<String, dynamic>>('/trips/$tripId'));

  Future<List<TripResponse>> listMine() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/me/trips');
      final envelope = ApiResponse<List<TripResponse>>.fromJson(
        res.data!,
        (raw) => (raw as List)
            .whereType<Map<String, dynamic>>()
            .map(TripResponse.fromJson)
            .toList(growable: false),
      );
      return envelope.data ?? const [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Driver kicks off the trip. Server returns the freshly mutated TripResponse
  /// (status IN_PROGRESS + first stop ACTIVE + currentStop set).
  Future<TripResponse> start(String tripId) =>
      _call(() => _dio.post<Map<String, dynamic>>('/trips/$tripId/start'));

  /// Driver completes the trip after every stop has been resolved.
  Future<TripResponse> complete(String tripId) =>
      _call(() => _dio.post<Map<String, dynamic>>('/trips/$tripId/complete'));

  /// Driver resolves the current active stop with PICK_UP / SKIP / CANCEL.
  Future<TripResponse> updateStop(
    String tripId,
    String stopId,
    UpdateTripStopRequest req,
  ) =>
      _call(() => _dio.patch<Map<String, dynamic>>(
            '/trips/$tripId/stops/$stopId',
            data: req.toJson(),
          ));

  Future<TripResponse> _call(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) async {
    try {
      final res = await call();
      final envelope = ApiResponse<TripResponse>.fromJson(
        res.data!,
        (raw) => TripResponse.fromJson(raw as Map<String, dynamic>),
      );
      if (envelope.data == null) {
        throw ApiException(
          statusCode: res.statusCode,
          code: 'EMPTY_RESPONSE',
          message: 'Server returned empty payload',
        );
      }
      return envelope.data!;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final tripApiProvider = Provider<TripApi>((ref) {
  return TripApi(ref.watch(dioProvider));
});

final tripDetailProvider =
    FutureProvider.autoDispose.family<TripResponse, String>((ref, tripId) {
  return ref.watch(tripApiProvider).get(tripId);
});

final myTripsProvider = FutureProvider.autoDispose<List<TripResponse>>((ref) {
  return ref.watch(tripApiProvider).listMine();
});
