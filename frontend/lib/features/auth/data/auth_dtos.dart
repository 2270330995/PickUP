import '../../user/data/user_dtos.dart';

class RegisterRequest {
  const RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
  });

  final String email;
  final String password;
  final String fullName;
  final String? phone;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'fullName': fullName,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
      };
}

class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSec,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresInSec;
  final UserResponse user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresInSec: (json['expiresInSec'] as num).toInt(),
      user: UserResponse.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
