class UserResponse {
  const UserResponse({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.systemRoles,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final List<String> systemRoles;
  final DateTime createdAt;

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    final roles = (json['systemRoles'] as List?) ?? const [];
    return UserResponse(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String?,
      systemRoles: roles.map((e) => e.toString()).toList(growable: false),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class UpdateUserRequest {
  const UpdateUserRequest({this.fullName, this.phone});

  final String? fullName;
  final String? phone;

  Map<String, dynamic> toJson() => {
        if (fullName != null) 'fullName': fullName,
        if (phone != null) 'phone': phone,
      };
}
