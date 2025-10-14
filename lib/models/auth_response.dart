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
  final String? uuid;
  final String? photoUrl;
  final bool profileComplete;
  final String? verificationCode;

  UserData({
    required this.id,
    required this.username,
    required this.isActive,
    required this.profile,
    required this.token,
    required this.refreshToken,
    this.uuid,
    this.photoUrl,
    this.profileComplete = false,
    this.verificationCode,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    // La nueva API v2 devuelve: {access_token, refresh_token, verification_code, user: {...}}
    // Necesitamos manejar ambos formatos para compatibilidad
    
    final userData = json['user'] ?? json; // Si hay 'user', usarlo, sino usar el json directamente
    
    return UserData(
      id: userData['id'] ?? json['id'] ?? 0,
      username: userData['username'] ?? json['username'] ?? '',
      isActive: userData['is_active'] ?? json['is_active'] ?? true,
      profile: UserProfile.fromJson(userData['profile'] ?? json['profile'] ?? {'phone_number': userData['phone_number'] ?? json['phone_number'] ?? ''}),
      token: json['access_token'] ?? json['token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      uuid: userData['uuid'] ?? json['uuid'],
      photoUrl: userData['photo_url'] ?? json['photo_url'],
      profileComplete: userData['profile_complete'] ?? json['profile_complete'] ?? false,
      verificationCode: json['verification_code'],
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
      'uuid': uuid,
      'photo_url': photoUrl,
      'profile_complete': profileComplete,
      'verification_code': verificationCode,
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