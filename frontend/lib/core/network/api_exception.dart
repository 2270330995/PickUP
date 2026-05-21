import 'package:dio/dio.dart';

import 'api_response.dart';

/// Normalized error thrown by all API call sites.
class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.fieldErrors = const [],
  });

  final int? statusCode;
  final String code;
  final String message;
  final List<FieldViolation> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isConflict => statusCode == 409;
  bool get isNotFound => statusCode == 404;

  /// Best-effort conversion of any Dio failure into a typed ApiException.
  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    final status = response?.statusCode;
    final data = response?.data;
    if (data is Map<String, dynamic>) {
      final api = ApiResponse<void>.fromJson(data, null);
      if (api.error != null) {
        return ApiException(
          statusCode: status,
          code: api.error!.code,
          message: api.error!.message,
          fieldErrors: api.error!.fieldErrors,
        );
      }
    }
    return ApiException(
      statusCode: status,
      code: _codeForType(e.type),
      message: e.message ?? 'Network error',
    );
  }

  @override
  String toString() => 'ApiException($statusCode $code): $message';

  static String _codeForType(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'TIMEOUT';
      case DioExceptionType.connectionError:
        return 'NETWORK_ERROR';
      case DioExceptionType.cancel:
        return 'CANCELLED';
      default:
        return 'UNKNOWN';
    }
  }
}
