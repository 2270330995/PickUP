import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'vehicle_dtos.dart';

class VehicleApi {
  VehicleApi(this._dio);
  final Dio _dio;

  Future<List<VehicleResponse>> listMine() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/vehicles');
      final envelope = ApiResponse<List<VehicleResponse>>.fromJson(
        res.data!,
        (raw) => (raw as List)
            .whereType<Map<String, dynamic>>()
            .map(VehicleResponse.fromJson)
            .toList(growable: false),
      );
      return envelope.data ?? const [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<VehicleResponse> create(CreateVehicleRequest req) =>
      _call(() => _dio.post<Map<String, dynamic>>('/vehicles', data: req.toJson()));

  Future<VehicleResponse> update(String id, UpdateVehicleRequest req) =>
      _call(() => _dio.patch<Map<String, dynamic>>('/vehicles/$id', data: req.toJson()));

  Future<void> delete(String id) async {
    try {
      await _dio.delete<dynamic>('/vehicles/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<VehicleResponse> _call(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) async {
    try {
      final res = await call();
      final envelope = ApiResponse<VehicleResponse>.fromJson(
        res.data!,
        (raw) => VehicleResponse.fromJson(raw as Map<String, dynamic>),
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

final vehicleApiProvider = Provider<VehicleApi>((ref) {
  return VehicleApi(ref.watch(dioProvider));
});

/// All vehicles owned by the current user.
final myVehiclesProvider = FutureProvider.autoDispose<List<VehicleResponse>>((ref) {
  return ref.watch(vehicleApiProvider).listMine();
});
