import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'auth_dtos.dart';

class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  Future<AuthResponse> register(RegisterRequest request) async {
    return _call('/auth/register', request.toJson());
  }

  Future<AuthResponse> login(LoginRequest request) async {
    return _call('/auth/login', request.toJson());
  }

  Future<AuthResponse> refresh(String refreshToken) async {
    return _call('/auth/refresh', {'refreshToken': refreshToken});
  }

  Future<void> logout() async {
    try {
      await _dio.post<dynamic>('/auth/logout');
    } on DioException {
      // logout is best-effort; tokens are cleared client-side regardless
    }
  }

  Future<AuthResponse> _call(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(path, data: body);
      final envelope = ApiResponse<AuthResponse>.fromJson(
        res.data!,
        (raw) => AuthResponse.fromJson(raw as Map<String, dynamic>),
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

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});
