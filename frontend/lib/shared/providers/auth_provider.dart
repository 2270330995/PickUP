import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/secure_token_storage.dart';
import '../../features/auth/data/auth_api.dart';
import '../../features/auth/data/auth_dtos.dart';
import '../../features/user/data/user_dtos.dart';

enum AuthStatus { loading, unauthenticated, authenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserResponse? user;
  final String? errorMessage;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserResponse? user,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref)
      : super(const AuthState(status: AuthStatus.loading)) {
    _ref.read(unauthorizedNotifierProvider).set(_forceLogout);
    _bootstrap();
  }

  final Ref _ref;

  SecureTokenStorage get _storage => _ref.read(secureTokenStorageProvider);
  AuthApi get _api => _ref.read(authApiProvider);

  Future<void> _bootstrap() async {
    final refresh = await _storage.readRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final result = await _api.refresh(refresh);
      await _storage.writeTokens(
        access: result.accessToken,
        refresh: result.refreshToken,
      );
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
    } on ApiException {
      await _storage.clear();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final result = await _api.login(LoginRequest(email: email, password: password));
      await _storage.writeTokens(
        access: result.accessToken,
        refresh: result.refreshToken,
      );
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
    } on ApiException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final result = await _api.register(RegisterRequest(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      ));
      await _storage.writeTokens(
        access: result.accessToken,
        refresh: result.refreshToken,
      );
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
    } on ApiException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _api.logout();
    await _storage.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Updates the cached user without changing auth status.
  /// Profile editing calls this so the avatar/name updates everywhere instantly.
  void updateCachedUser(UserResponse user) {
    if (state.isAuthenticated) {
      state = state.copyWith(user: user);
    }
  }

  void _forceLogout() {
    // fire-and-forget; can't await inside a non-async dio interceptor callback
    _storage.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref),
);
