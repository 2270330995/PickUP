import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'event_dtos.dart';

class EventApi {
  EventApi(this._dio);
  final Dio _dio;

  Future<List<EventResponse>> listEvents({String scope = 'mine'}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/events',
        queryParameters: {'scope': scope},
      );
      final envelope = ApiResponse<List<EventResponse>>.fromJson(
        res.data!,
        (raw) => (raw as List)
            .whereType<Map<String, dynamic>>()
            .map(EventResponse.fromJson)
            .toList(growable: false),
      );
      return envelope.data ?? const [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<EventResponse> get(String id) => _eventCall(() => _dio.get<Map<String, dynamic>>('/events/$id'));

  Future<EventResponse> create(CreateEventRequest req) =>
      _eventCall(() => _dio.post<Map<String, dynamic>>('/events', data: req.toJson()));

  Future<EventResponse> update(String id, UpdateEventRequest req) =>
      _eventCall(() => _dio.patch<Map<String, dynamic>>('/events/$id', data: req.toJson()));

  Future<void> delete(String id) async {
    try {
      await _dio.delete<dynamic>('/events/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<EventResponse> close(String id) =>
      _eventCall(() => _dio.post<Map<String, dynamic>>('/events/$id/close'));

  Future<EventResponse> cancel(String id) =>
      _eventCall(() => _dio.post<Map<String, dynamic>>('/events/$id/cancel'));

  Future<EventResponse> _eventCall(Future<Response<Map<String, dynamic>>> Function() call) async {
    try {
      final res = await call();
      final envelope = ApiResponse<EventResponse>.fromJson(
        res.data!,
        (raw) => EventResponse.fromJson(raw as Map<String, dynamic>),
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

final eventApiProvider = Provider<EventApi>((ref) {
  return EventApi(ref.watch(dioProvider));
});

/// Single event detail (auto-refreshes on invalidate).
final eventDetailProvider =
    FutureProvider.autoDispose.family<EventResponse, String>((ref, id) {
  return ref.watch(eventApiProvider).get(id);
});

/// Events I organize.
final myEventsProvider = FutureProvider.autoDispose<List<EventResponse>>((ref) {
  return ref.watch(eventApiProvider).listEvents(scope: 'mine');
});

/// Open events I'm not yet joined to.
final openEventsProvider = FutureProvider.autoDispose<List<EventResponse>>((ref) {
  return ref.watch(eventApiProvider).listEvents(scope: 'open');
});
