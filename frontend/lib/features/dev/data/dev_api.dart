import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';

class DevAccountInfo {
  const DevAccountInfo({
    required this.email,
    required this.fullName,
    required this.role,
    required this.password,
  });

  final String email;
  final String fullName;
  final String role;
  final String password;

  factory DevAccountInfo.fromJson(Map<String, dynamic> json) {
    return DevAccountInfo(
      email: json['email'] as String,
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? '',
      password: json['password'] as String? ?? 'test',
    );
  }
}

class DevSeedResponse {
  const DevSeedResponse({
    required this.eventId,
    required this.eventTitle,
    required this.alreadyExisted,
    required this.accounts,
  });

  final String eventId;
  final String eventTitle;
  final bool alreadyExisted;
  final List<DevAccountInfo> accounts;

  factory DevSeedResponse.fromJson(Map<String, dynamic> json) {
    final accounts = (json['accounts'] as List?) ?? const [];
    return DevSeedResponse(
      eventId: json['eventId'] as String,
      eventTitle: json['eventTitle'] as String? ?? '',
      alreadyExisted: json['alreadyExisted'] as bool? ?? false,
      accounts: accounts
          .whereType<Map<String, dynamic>>()
          .map(DevAccountInfo.fromJson)
          .toList(growable: false),
    );
  }
}

class DevApi {
  DevApi(this._dio);
  final Dio _dio;

  Future<List<DevAccountInfo>> listAccounts() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/dev/accounts');
      final envelope = ApiResponse<List<DevAccountInfo>>.fromJson(
        res.data!,
        (raw) => (raw as List)
            .whereType<Map<String, dynamic>>()
            .map(DevAccountInfo.fromJson)
            .toList(growable: false),
      );
      return envelope.data ?? const [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<DevSeedResponse> seed() async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/dev/seed');
      final envelope = ApiResponse<DevSeedResponse>.fromJson(
        res.data!,
        (raw) => DevSeedResponse.fromJson(raw as Map<String, dynamic>),
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

final devApiProvider = Provider<DevApi>((ref) {
  return DevApi(ref.watch(dioProvider));
});

final devAccountsProvider = FutureProvider.autoDispose<List<DevAccountInfo>>((ref) {
  return ref.watch(devApiProvider).listAccounts();
});
