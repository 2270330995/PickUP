import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_token_storage.dart';

/// Backend base URL. Override at build time:
///   flutter run --dart-define=PICKUP_API_BASE_URL=http://10.0.2.2:8080
const String _defaultBaseUrl = String.fromEnvironment(
  'PICKUP_API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

/// Subscribed by [AuthController] so that 401s from the dio interceptor
/// can clear local tokens and bounce the user back to /login.
typedef UnauthorizedHandler = void Function();

class UnauthorizedNotifier {
  UnauthorizedHandler? _handler;
  void set(UnauthorizedHandler? handler) => _handler = handler;
  void trigger() => _handler?.call();
}

final unauthorizedNotifierProvider = Provider<UnauthorizedNotifier>((_) {
  return UnauthorizedNotifier();
});

class ApiClient {
  ApiClient(this._dio);
  final Dio _dio;
  Dio get raw => _dio;
}

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureTokenStorageProvider);
  final unauthorized = ref.watch(unauthorizedNotifierProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: '$_defaultBaseUrl/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // public auth endpoints (login/register/refresh) intentionally surface 401
          // as ApiException without forcing a session reset.
          final path = error.requestOptions.path;
          final isAuthEndpoint = path.startsWith('/auth/');
          if (!isAuthEndpoint) {
            unauthorized.trigger();
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});
