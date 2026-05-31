import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'participant_dtos.dart';

class ParticipantApi {
  ParticipantApi(this._dio);
  final Dio _dio;

  Future<List<EventParticipantResponse>> list(String eventId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/events/$eventId/participants');
      final envelope = ApiResponse<List<EventParticipantResponse>>.fromJson(
        res.data!,
        (raw) => (raw as List)
            .whereType<Map<String, dynamic>>()
            .map(EventParticipantResponse.fromJson)
            .toList(growable: false),
      );
      return envelope.data ?? const [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<EventParticipantResponse> selfJoin(String eventId, JoinEventRequest req) {
    return _call(() => _dio.post<Map<String, dynamic>>(
          '/events/$eventId/participants',
          data: req.toJson(),
        ));
  }

  Future<EventParticipantResponse> approve(String eventId, String participantId) {
    return _call(() => _dio.post<Map<String, dynamic>>(
          '/events/$eventId/participants/$participantId/approve',
        ));
  }

  Future<EventParticipantResponse> reject(String eventId, String participantId) {
    return _call(() => _dio.post<Map<String, dynamic>>(
          '/events/$eventId/participants/$participantId/reject',
        ));
  }

  Future<EventParticipantResponse> confirm(String eventId, String participantId) {
    return _call(() => _dio.post<Map<String, dynamic>>(
          '/events/$eventId/participants/$participantId/confirm',
        ));
  }

  Future<EventParticipantResponse> cancel(String eventId, String participantId) {
    return _call(() => _dio.post<Map<String, dynamic>>(
          '/events/$eventId/participants/$participantId/cancel',
        ));
  }

  Future<EventParticipantResponse> rejoin(String eventId, String participantId) {
    return _call(() => _dio.post<Map<String, dynamic>>(
          '/events/$eventId/participants/$participantId/rejoin',
        ));
  }

  Future<void> remove(String eventId, String participantId) async {
    try {
      await _dio.delete<dynamic>('/events/$eventId/participants/$participantId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Driver attaches (or clears, via [vehicleId] = null) one of their vehicles
  /// for a specific event.
  Future<EventParticipantResponse> setVehicle(
    String eventId,
    String participantId,
    String? vehicleId,
  ) {
    return _call(() => _dio.patch<Map<String, dynamic>>(
          '/events/$eventId/participants/$participantId/vehicle',
          data: UpdateParticipantVehicleRequest(vehicleId: vehicleId).toJson(),
        ));
  }

  /// Passenger sets or updates their pickup location for a specific event.
  Future<EventParticipantResponse> setPickup(
    String eventId,
    String participantId,
    UpdateParticipantPickupRequest request,
  ) {
    return _call(() => _dio.patch<Map<String, dynamic>>(
          '/events/$eventId/participants/$participantId/pickup',
          data: request.toJson(),
        ));
  }

  Future<EventParticipantResponse> _call(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) async {
    try {
      final res = await call();
      final envelope = ApiResponse<EventParticipantResponse>.fromJson(
        res.data!,
        (raw) => EventParticipantResponse.fromJson(raw as Map<String, dynamic>),
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

final participantApiProvider = Provider<ParticipantApi>((ref) {
  return ParticipantApi(ref.watch(dioProvider));
});

final eventParticipantsProvider = FutureProvider.autoDispose
    .family<List<EventParticipantResponse>, String>((ref, eventId) {
  return ref.watch(participantApiProvider).list(eventId);
});
