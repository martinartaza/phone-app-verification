class NetworkUser {
  final String username;
  final String uuid;
  final String phone;
  final String? photoUrl; // full URL
  final int invitationId;
  final String? invitationMessage;

  NetworkUser({
    required this.username,
    required this.uuid,
    required this.phone,
    required this.photoUrl,
    required this.invitationId,
    this.invitationMessage,
  });
}

class RegistrationStatus {
  final int fulbitoId;
  final bool registrationOpen;
  final String opensAt;
  final String currentTime;
  final int timeUntilOpen;
  final bool invitationOpen;
  final String? invitationOpensAt;
  final int invitationTimeUntilOpen;
  final String nextMatchDate;
  final String nextMatchHour;
  final int capacity;
  final int registeredCount;
  final int availableSpots;
  final bool canRegister;
  final List<Map<String, dynamic>> players;
  final int? userPosition;
  final String? userType;

  RegistrationStatus({
    required this.fulbitoId,
    required this.registrationOpen,
    required this.opensAt,
    required this.currentTime,
    required this.timeUntilOpen,
    required this.invitationOpen,
    this.invitationOpensAt,
    required this.invitationTimeUntilOpen,
    required this.nextMatchDate,
    required this.nextMatchHour,
    required this.capacity,
    required this.registeredCount,
    required this.availableSpots,
    required this.canRegister,
    required this.players,
    this.userPosition,
    this.userType,
  });

  factory RegistrationStatus.fromJson(Map<String, dynamic> json) {
    return RegistrationStatus(
      fulbitoId: json['fulbito_id'] ?? 0,
      registrationOpen: json['registration_open'] ?? false,
      opensAt: json['opens_at'] ?? '',
      currentTime: json['current_time'] ?? '',
      timeUntilOpen: json['time_until_open'] ?? 0,
      invitationOpen: json['invitation_open'] ?? false,
      invitationOpensAt: json['invitation_opens_at'],
      invitationTimeUntilOpen: json['invitation_time_until_open'] ?? 0,
      nextMatchDate: json['next_match_date'] ?? '',
      nextMatchHour: json['next_match_hour'] ?? '',
      capacity: json['capacity'] ?? 0,
      registeredCount: json['registered_count'] ?? 0,
      availableSpots: json['available_spots'] ?? 0,
      canRegister: json['can_register'] ?? false,
      players: (json['players'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
      userPosition: json['user_position'],
      userType: json['user_type'],
    );
  }
}

class NetworkData {
  final List<NetworkUser> network;
  final List<NetworkUser> invitationPending;

  NetworkData({
    required this.network,
    required this.invitationPending,
  });
}

class Fulbito {
  final int id;
  final String name;
  final String place;
  final String day;
  final String hour;
  final String registrationStartDay;
  final String registrationStartHour;
  final String ownerName;
  final String ownerPhone;
  final String? ownerPhotoUrl; // full URL
  final int? invitationId;
  final int capacity;
  final String? message;
  final String createdAt;
  final String updatedAt;
  final RegistrationStatus? registrationStatus;

  Fulbito({
    required this.id,
    required this.name,
    required this.place,
    required this.day,
    required this.hour,
    required this.registrationStartDay,
    required this.registrationStartHour,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerPhotoUrl,
    required this.invitationId,
    required this.capacity,
    this.message,
    required this.createdAt,
    required this.updatedAt,
    this.registrationStatus,
  });

  bool get isOwner => invitationId == null;
}

class FulbitosData {
  final List<Fulbito> myFulbitos;
  final List<Fulbito> acceptFulbitos;
  final List<Fulbito> pendingFulbitos;
  final int? nextEvent; // segundos hasta el próximo cambio en inscripciones/invitaciones

  FulbitosData({
    required this.myFulbitos,
    required this.acceptFulbitos,
    required this.pendingFulbitos,
    this.nextEvent,
  });

  bool get isEmpty => myFulbitos.isEmpty && acceptFulbitos.isEmpty && pendingFulbitos.isEmpty;
}

