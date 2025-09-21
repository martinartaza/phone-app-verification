class FulbitoCreation {
  final String name;
  final String place;
  final String day;
  final String hour;
  final String registrationStartDay;
  final String registrationStartHour;
  final String? invitationGuestStartDay;
  final String? invitationGuestStartHour;
  final int capacity;

  FulbitoCreation({
    required this.name,
    required this.place,
    required this.day,
    required this.hour,
    required this.registrationStartDay,
    required this.registrationStartHour,
    this.invitationGuestStartDay,
    this.invitationGuestStartHour,
    required this.capacity,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'name': name,
      'place': place,
      'day': day,
      'hour': hour,
      'registration_start_day': registrationStartDay,
      'registration_start_hour': registrationStartHour,
      'capacity': capacity,
    };
    
    // Solo agregar los campos de invitaciones si están definidos
    if (invitationGuestStartDay != null) {
      json['invitation_guest_start_day'] = invitationGuestStartDay!;
    }
    if (invitationGuestStartHour != null) {
      json['invitation_guest_start_hour'] = invitationGuestStartHour!;
    }
    
    return json;
  }
}
