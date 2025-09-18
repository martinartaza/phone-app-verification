class FulbitoCreation {
  final String name;
  final String place;
  final String day;
  final String hour;
  final String registrationStartDay;
  final String registrationStartHour;
  final int capacity;

  FulbitoCreation({
    required this.name,
    required this.place,
    required this.day,
    required this.hour,
    required this.registrationStartDay,
    required this.registrationStartHour,
    required this.capacity,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'place': place,
      'day': day,
      'hour': hour,
      'registration_start_day': registrationStartDay,
      'registration_start_hour': registrationStartHour,
      'capacity': capacity,
    };
  }
}
