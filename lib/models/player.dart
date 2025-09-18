class Player {
  final int id;
  final String username;
  final String phone;
  final String? photoUrl;
  final String typePlayer;
  final String type;
  final Map<String, double> averageSkills;

  Player({
    required this.id,
    required this.username,
    required this.phone,
    this.photoUrl,
    required this.typePlayer,
    required this.type,
    required this.averageSkills,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      photoUrl: json['photoUrl'],
      typePlayer: json['type_player'] ?? '',
      type: json['type'] ?? '',
      averageSkills: _parseAverageSkills(json['averageSkills']),
    );
  }

  static Map<String, double> _parseAverageSkills(dynamic skills) {
    if (skills == null || skills is! Map<String, dynamic>) {
      return {};
    }
    
    // Mapeo de inglés a español
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
        // Usar la clave en español para el mapeo interno
        final spanishKey = skillMapping[key] ?? key;
        result[spanishKey] = value.toDouble();
      }
    });
    
    return result;
  }
}

class FulbitoPlayersResponse {
  final List<Player> players;
  final List<Player> pendingAccept;
  final List<Player> enabledToRegister;
  final List<Player> rejected;

  FulbitoPlayersResponse({
    required this.players,
    required this.pendingAccept,
    required this.enabledToRegister,
    required this.rejected,
  });

  factory FulbitoPlayersResponse.fromJson(Map<String, dynamic> json) {
    final playersList = json['players'] as List<dynamic>? ?? [];
    final pendingList = json['pending_accept'] as List<dynamic>? ?? [];
    final enabledList = json['enabled_to_register'] as List<dynamic>? ?? [];
    final rejectedList = json['rejected'] as List<dynamic>? ?? [];

    return FulbitoPlayersResponse(
      players: playersList.map((player) => Player.fromJson(player)).toList(),
      pendingAccept: pendingList.map((p) => Player.fromJson(p)).toList(),
      enabledToRegister: enabledList.map((p) => Player.fromJson(p)).toList(),
      rejected: rejectedList.map((p) => Player.fromJson(p)).toList(),
    );
  }
}
