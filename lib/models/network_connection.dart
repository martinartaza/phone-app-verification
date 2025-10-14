class NetworkConnection {
  final int id;
  final NetworkConnectionUser fromUser;
  final NetworkConnectionUser? toUser; // Puede ser null si el usuario no existe aún
  final String? toPhoneNumber; // Solo presente si toUser es null
  final String message;
  final String status; // 'pending', 'accepted', 'rejected'
  final String createdAt;
  final String? updatedAt;

  NetworkConnection({
    required this.id,
    required this.fromUser,
    this.toUser,
    this.toPhoneNumber,
    required this.message,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory NetworkConnection.fromJson(Map<String, dynamic> json) {
    return NetworkConnection(
      id: json['id'] ?? 0,
      fromUser: NetworkConnectionUser.fromJson(json['from_user'] ?? {}),
      toUser: json['to_user'] != null 
          ? NetworkConnectionUser.fromJson(json['to_user']) 
          : null,
      toPhoneNumber: json['to_phone_number'],
      message: json['message'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user': fromUser.toJson(),
      'to_user': toUser?.toJson(),
      'to_phone_number': toPhoneNumber,
      'message': message,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get userNotFound => toUser == null && toPhoneNumber != null;
}

class NetworkConnectionUser {
  final int id;
  final String username;
  final String phone;
  final String? photoUrl;

  NetworkConnectionUser({
    required this.id,
    required this.username,
    required this.phone,
    this.photoUrl,
  });

  factory NetworkConnectionUser.fromJson(Map<String, dynamic> json) {
    return NetworkConnectionUser(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'phone': phone,
      'photo_url': photoUrl,
    };
  }
}

class NetworkInviteResponse {
  final String status; // 'success', 'user_not_found', 'error'
  final String message;
  final String? urlFulbitoApp;
  final String? urlPaddlecitoApp;
  final NetworkConnection? data;

  NetworkInviteResponse({
    required this.status,
    required this.message,
    this.urlFulbitoApp,
    this.urlPaddlecitoApp,
    this.data,
  });

  factory NetworkInviteResponse.fromJson(Map<String, dynamic> json) {
    return NetworkInviteResponse(
      status: json['status'] ?? 'error',
      message: json['message'] ?? 'Respuesta sin mensaje',
      urlFulbitoApp: json['url_fulbito_app'],
      urlPaddlecitoApp: json['url_paddlecito_app'],
      data: json['data'] != null 
          ? NetworkConnection.fromJson(json['data']) 
          : null,
    );
  }

  bool get shouldOpenWhatsApp => status == 'user_not_found';
  bool get isSuccess => status == 'success';
  bool get isError => status == 'error';
}

