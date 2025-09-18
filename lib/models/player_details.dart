class PlayerDetails {
  final String uuid;
  final String phoneNumber;
  final String firstName;
  final String? photoUrl;
  final int age;
  final bool isGoalkeeper;
  final bool isForward;
  final bool isMidfielder;
  final bool isDefender;
  final Map<String, double> selfPerception;
  final Map<String, double> averageOpinion;
  final int numberOfOpinions;

  PlayerDetails({
    required this.uuid,
    required this.phoneNumber,
    required this.firstName,
    this.photoUrl,
    required this.age,
    required this.isGoalkeeper,
    required this.isForward,
    required this.isMidfielder,
    required this.isDefender,
    required this.selfPerception,
    required this.averageOpinion,
    required this.numberOfOpinions,
  });

  factory PlayerDetails.fromJson(Map<String, dynamic> json) {
    return PlayerDetails(
      uuid: json['uuid'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      firstName: json['first_name'] ?? '',
      photoUrl: json['photo_url'],
      age: json['age'] ?? 0,
      isGoalkeeper: json['is_goalkeeper'] ?? false,
      isForward: json['is_forward'] ?? false,
      isMidfielder: json['is_midfielder'] ?? false,
      isDefender: json['is_defender'] ?? false,
      selfPerception: _parseSkills(json['self_perception']),
      averageOpinion: _parseSkills(json['average_opinion']),
      numberOfOpinions: json['number_of_opinions'] ?? 0,
    );
  }

  static Map<String, double> _parseSkills(dynamic skills) {
    if (skills == null || skills is! Map<String, dynamic>) {
      return {};
    }
    
    // Mapear de inglés a español para uso interno
    final Map<String, String> skillMapping = {
      'speed': 'velocidad',
      'passing': 'pases',
      'stamina': 'resistencia',
      'shooting': 'tiro_arco',
      'defending': 'defensa',
      'dribbling': 'gambeta',
    };
    
    final Map<String, double> result = {};
    skills.forEach((key, value) {
      if (value is num) {
        final spanishKey = skillMapping[key] ?? key;
        result[spanishKey] = value.toDouble();
      }
    });
    
    return result;
  }
}
