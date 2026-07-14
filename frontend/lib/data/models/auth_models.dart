class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class LoginResponse {
  final String accessToken;
  final String tokenType;
  final int? userId;
  final String? username;
  final String? role;
  final bool mustChangePassword;
  final UserResponse? user;

  const LoginResponse({
    required this.accessToken,
    this.tokenType = 'Bearer',
    this.userId,
    this.username,
    this.role,
    this.mustChangePassword = false,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final nestedUser = json['user'] is Map<String, dynamic>
        ? UserResponse.fromJson(json['user'] as Map<String, dynamic>)
        : null;
    final parsedRole = _normalizeRole(
      nestedUser?.role ?? json['role'] as String?,
    );
    final parsedUserId = json['userId'] as int? ?? json['id'] as int?;
    final parsedUsername = json['username'] as String?;

    return LoginResponse(
      accessToken:
          json['accessToken'] as String? ??
          json['access_token'] as String? ??
          '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      userId: parsedUserId,
      username: parsedUsername,
      role: parsedRole,
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      user:
          nestedUser ??
          UserResponse(
            id: parsedUserId,
            username: parsedUsername,
            role: parsedRole,
          ),
    );
  }
}

class ForgotPasswordRequest {
  final String usernameOrEmail;

  const ForgotPasswordRequest({required this.usernameOrEmail});

  Map<String, dynamic> toJson() => {'usernameOrEmail': usernameOrEmail};
}

class ResetForgottenPasswordRequest {
  final String token;
  final String newPassword;
  final String confirmPassword;

  const ResetForgottenPasswordRequest({
    required this.token,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'newPassword': newPassword,
    'confirmPassword': confirmPassword,
  };
}

class UserResponse {
  final int? id;
  final String? username;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? role;
  final String? idNumber;
  final String? address;
  final bool? active;

  const UserResponse({
    this.id,
    this.username,
    this.fullName,
    this.email,
    this.phone,
    this.role,
    this.idNumber,
    this.address,
    this.active,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as int?,
      username: json['username'] as String?,
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: _normalizeRole(json['role'] as String?),
      idNumber: json['idNumber'] as String?,
      address: json['address'] as String?,
      active: json['active'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'role': role,
    'idNumber': idNumber,
    'address': address,
    'active': active,
  };

  String get displayName => fullName ?? username ?? 'Người dùng';
  String get initials {
    final name = fullName ?? username ?? 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}

String? _normalizeRole(String? role) {
  if (role == null || role.isEmpty) return role;
  return role.replaceFirst('ROLE_', '').toUpperCase();
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    'oldPassword': currentPassword,
    'newPassword': newPassword,
    'confirmPassword': confirmPassword,
  };
}
