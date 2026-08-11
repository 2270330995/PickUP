import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'assignment_dtos.dart';

class AssignmentApi {
  AssignmentApi(this._dio);
  final Dio _dio;

  /// Read-only plan view: returns existing trips + the list of confirmed
  /// passengers not yet placed on any trip.
  Future<AssignmentPlanResponse> getPlan(String eventId) {
    return _call(() => _dio.get<Map<String, dynamic>>('/events/$eventId/trips'));
  }

  /// Atomic full-replace of an event's assignment plan.
  Future<AssignmentPlanResponse> submit(
    String eventId,
    SubmitAssignmentsRequest req,
  ) {
    return _call(() => _dio.post<Map<String, dynamic>>(
          '/events/$eventId/assignments',
          data: req.toJson(),
        ));
  }

  /// Deterministic auto-assignment for an event (organizer only).
  Future<AssignmentPlanResponse> generateAssignments(String eventId) {
    return _call(() => _dio.post<Map<String, dynamic>>(
          '/events/$eventId/planning/generate-assignments',
        ));
  }

  Future<AssignmentPlanResponse> _call(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) async {
    try {
      final res = await call();
      final envelope = ApiResponse<AssignmentPlanResponse>.fromJson(
        res.data!,
        (raw) => AssignmentPlanResponse.fromJson(raw as Map<String, dynamic>),
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

final assignmentApiProvider = Provider<AssignmentApi>((ref) {
  return AssignmentApi(ref.watch(dioProvider));
});

final eventAssignmentPlanProvider = FutureProvider.autoDispose
    .family<AssignmentPlanResponse, String>((ref, eventId) {
  return ref.watch(assignmentApiProvider).getPlan(eventId);
});
