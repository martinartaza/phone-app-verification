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
    
    final Map<String, double> result = {};
    skills.forEach((key, value) {
      if (value is num) {
        result[key] = value.toDouble();
      }
    });
    
    return result;
  }
}

class FulbitoPlayersResponse {
  final List<Player> players;

  FulbitoPlayersResponse({
    required this.players,
  });

  factory FulbitoPlayersResponse.fromJson(Map<String, dynamic> json) {
    final playersList = json['players'] as List<dynamic>? ?? [];
    return FulbitoPlayersResponse(
      players: playersList.map((player) => Player.fromJson(player)).toList(),
    );
  }
}
