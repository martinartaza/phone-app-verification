class NetworkUser {
  final String username;
  final String uuid;
  final String phone;
  final String? photoUrl; // full URL
  final int invitationId;

  NetworkUser({
    required this.username,
    required this.uuid,
    required this.phone,
    required this.photoUrl,
    required this.invitationId,
  });
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
  final String createdAt;
  final String updatedAt;

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
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOwner => invitationId == null;
}

class FulbitosData {
  final List<Fulbito> myFulbitos;
  final List<Fulbito> acceptFulbitos;
  final List<Fulbito> pendingFulbitos;

  FulbitosData({
    required this.myFulbitos,
    required this.acceptFulbitos,
    required this.pendingFulbitos,
  });

  bool get isEmpty => myFulbitos.isEmpty && acceptFulbitos.isEmpty && pendingFulbitos.isEmpty;
}

