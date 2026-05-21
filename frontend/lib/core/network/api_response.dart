/// Mirrors the backend `ApiResponse<T>` envelope.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.data,
    required this.error,
  });

  final bool success;
  final T? data;
  final ApiError? error;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?)? dataParser,
  ) {
    final raw = json['data'];
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: raw == null || dataParser == null ? null : dataParser(raw),
      error: json['error'] == null
          ? null
          : ApiError.fromJson(json['error'] as Map<String, dynamic>),
    );
  }
}

class ApiError {
  const ApiError({
    required this.code,
    required this.message,
    this.fieldErrors = const [],
  });

  final String code;
  final String message;
  final List<FieldViolation> fieldErrors;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final fes = (json['fieldErrors'] as List?) ?? const [];
    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? 'Unknown error',
      fieldErrors: fes
          .whereType<Map<String, dynamic>>()
          .map(FieldViolation.fromJson)
          .toList(growable: false),
    );
  }
}

class FieldViolation {
  const FieldViolation({required this.field, required this.message});

  final String field;
  final String message;

  factory FieldViolation.fromJson(Map<String, dynamic> json) {
    return FieldViolation(
      field: json['field'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}
