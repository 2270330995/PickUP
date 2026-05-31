import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT access + refresh tokens.
///
/// Mobile and web use [FlutterSecureStorage]. Desktop (macOS / Windows / Linux)
/// uses [SharedPreferences] so local dev does not require Keychain entitlements
/// or Apple code signing.
class TokenStorage {
  TokenStorage._(this._backend);

  static const _accessTokenKey = 'pickup.access_token';
  static const _refreshTokenKey = 'pickup.refresh_token';

  final _TokenBackend _backend;

  factory TokenStorage.create() {
    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      return TokenStorage._(_SharedPrefsBackend());
    }
    return TokenStorage._(_SecureStorageBackend(const FlutterSecureStorage()));
  }

  Future<String?> readAccessToken() => _backend.read(_accessTokenKey);

  Future<String?> readRefreshToken() => _backend.read(_refreshTokenKey);

  Future<void> writeTokens({required String access, required String refresh}) async {
    await _backend.write(_accessTokenKey, access);
    await _backend.write(_refreshTokenKey, refresh);
  }

  Future<void> clear() async {
    await _backend.delete(_accessTokenKey);
    await _backend.delete(_refreshTokenKey);
  }
}

abstract class _TokenBackend {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class _SecureStorageBackend implements _TokenBackend {
  _SecureStorageBackend(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class _SharedPrefsBackend implements _TokenBackend {
  SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<String?> read(String key) async => (await _instance()).getString(key);

  @override
  Future<void> write(String key, String value) async {
    await (await _instance()).setString(key, value);
  }

  @override
  Future<void> delete(String key) async {
    await (await _instance()).remove(key);
  }
}

final secureTokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage.create();
});
