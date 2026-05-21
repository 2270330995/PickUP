import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'user_dtos.dart';

class UserApi {
  UserApi(this._dio);
  final Dio _dio;

  Future<UserResponse> getMe() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/me');
      return _parse(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserResponse> updateMe(UpdateUserRequest request) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/users/me',
        data: request.toJson(),
      );
      return _parse(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  UserResponse _parse(Response<Map<String, dynamic>> res) {
    final envelope = ApiResponse<UserResponse>.fromJson(
      res.data!,
      (raw) => UserResponse.fromJson(raw as Map<String, dynamic>),
    );
    if (envelope.data == null) {
      throw ApiException(
        statusCode: res.statusCode,
        code: 'EMPTY_RESPONSE',
        message: 'Server returned empty payload',
      );
    }
    return envelope.data!;
  }
}

final userApiProvider = Provider<UserApi>((ref) {
  return UserApi(ref.watch(dioProvider));
});

final currentUserProvider = FutureProvider.autoDispose<UserResponse>((ref) async {
  return ref.watch(userApiProvider).getMe();
});
