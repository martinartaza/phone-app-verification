class AuthResponse {
  final String status;
  final String message;
  final UserData? data;

  AuthResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null ? UserData.fromJson(json['data']) : null,
    );
  }

  bool get isSuccess => status == 'success';
}

class UserData {
  final int id;
  final String username;
  final bool isActive;
  final UserProfile profile;
  final String token;
  final String refreshToken;

  UserData({
    required this.id,
    required this.username,
    required this.isActive,
    required this.profile,
    required this.token,
    required this.refreshToken,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      isActive: json['is_active'] ?? false,
      profile: UserProfile.fromJson(json['profile'] ?? {}),
      token: json['token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'is_active': isActive,
      'profile': profile.toJson(),
      'token': token,
      'refresh_token': refreshToken,
    };
  }
}

class UserProfile {
  final String phoneNumber;
  final bool isVerified;

  UserProfile({
    required this.phoneNumber,
    required this.isVerified,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      phoneNumber: json['phone_number'] ?? '',
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'is_verified': isVerified,
    };
  }
}