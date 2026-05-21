import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'dashboard_dtos.dart';

class DashboardApi {
  DashboardApi(this._dio);
  final Dio _dio;

  Future<OrganizerDashboardResponse> getOrganizerDashboard() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/organizer/dashboard');
      final envelope = ApiResponse<OrganizerDashboardResponse>.fromJson(
        res.data!,
        (raw) => OrganizerDashboardResponse.fromJson(raw as Map<String, dynamic>),
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

  Future<EventDashboardResponse> getEventDashboard(String eventId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/events/$eventId/dashboard');
      final envelope = ApiResponse<EventDashboardResponse>.fromJson(
        res.data!,
        (raw) => EventDashboardResponse.fromJson(raw as Map<String, dynamic>),
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

final dashboardApiProvider = Provider<DashboardApi>((ref) {
  return DashboardApi(ref.watch(dioProvider));
});

final organizerDashboardProvider =
    FutureProvider.autoDispose<OrganizerDashboardResponse>((ref) {
  return ref.watch(dashboardApiProvider).getOrganizerDashboard();
});

final eventDashboardProvider = FutureProvider.autoDispose
    .family<EventDashboardResponse, String>((ref, eventId) {
  return ref.watch(dashboardApiProvider).getEventDashboard(eventId);
});
