import 'package:flutter/material.dart';
import 'package:matchday/config/api_config.dart';

class TeamsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _players = [];
  List<Map<String, dynamic>> _team1 = [];
  List<Map<String, dynamic>> _team2 = [];
  List<Map<String, dynamic>> _unassignedPlayers = [];
  
  // Promedios de skills por equipo
  Map<String, double> _team1AverageSkills = {};
  Map<String, double> _team2AverageSkills = {};

  // Getters
  List<Map<String, dynamic>> get players => _players;
  List<Map<String, dynamic>> get team1 => _team1;
  List<Map<String, dynamic>> get team2 => _team2;
  List<Map<String, dynamic>> get unassignedPlayers => _unassignedPlayers;
  
  int get team1Count => _team1.length;
  int get team2Count => _team2.length;
  int get unassignedCount => _unassignedPlayers.length;
  
  // Getters para promedios de skills
  Map<String, double> get team1AverageSkills => _team1AverageSkills;
  Map<String, double> get team2AverageSkills => _team2AverageSkills;
  
  // Verificar si hay datos suficientes para mostrar hexágono
  bool get hasTeamsData => _team1.isNotEmpty || _team2.isNotEmpty;

  // Inicializar con jugadores registrados
  void initializeWithPlayers(List<Map<String, dynamic>> registeredPlayers) {
    print('🔄 initializeWithPlayers - Procesando ${registeredPlayers.length} jugadores');
    
    _players = registeredPlayers.map((player) {
      print('🔄 Mapeando jugador original: $player');
      
      // Usamos position como identificador único interno para evitar colisiones
      final mappedPlayer = {
        'id': player['position'],
        'name': player['username'] ?? '',
        'photoUrl': player['photo_url'] ?? '',
        'team': 0, // Todos empiezan sin asignar
        'position': player['position'] ?? 0,
        'registeredAt': player['registered_at'] ?? '',
        'averageSkills': player['averageSkills'], // ¡IMPORTANTE: Conservar averageSkills!
      };
      
      print('🔄 Jugador mapeado: $mappedPlayer');
      return mappedPlayer;
    }).toList();
    
    _updateTeamLists();
    notifyListeners();
  }

  // Mover jugador a un equipo específico
  void movePlayerToTeam(int playerId, int team) {
    print('🎯 movePlayerToTeam - Jugador ID: $playerId, Equipo: $team');
    
    final playerIndex = _players.indexWhere((player) => player['id'] == playerId);
    if (playerIndex == -1) {
      print('❌ movePlayerToTeam - Jugador no encontrado');
      return;
    }

    final playerName = _players[playerIndex]['name'];
    
    // Si el jugador ya está en ese equipo, lo removemos (vuelve a no asignado)
    if (_players[playerIndex]['team'] == team) {
      _players[playerIndex]['team'] = 0;
      print('🔄 movePlayerToTeam - $playerName removido del equipo $team (ahora sin asignar)');
    } else {
      _players[playerIndex]['team'] = team;
      print('➕ movePlayerToTeam - $playerName asignado al equipo $team');
    }
    
    _updateTeamLists();
    notifyListeners();
  }

  // Mover jugador a Team 1
  void moveToTeam1(int playerId) {
    movePlayerToTeam(playerId, 1);
  }

  // Mover jugador a Team 2
  void moveToTeam2(int playerId) {
    movePlayerToTeam(playerId, 2);
  }

  // Obtener color del borde según el equipo
  Color getPlayerBorderColor(int team) {
    switch (team) {
      case 1:
        return const Color(0xFF3B82F6); // Azul para Team 1
      case 2:
        return const Color(0xFFEF4444); // Rojo para Team 2
      default:
        return const Color(0xFFE2E8F0); // Gris para no asignado
    }
  }

  // Obtener color del texto según el equipo
  Color getPlayerTextColor(int team) {
    switch (team) {
      case 1:
        return const Color(0xFF3B82F6); // Azul para Team 1
      case 2:
        return const Color(0xFFEF4444); // Rojo para Team 2
      default:
        return const Color(0xFF374151); // Gris oscuro para no asignado
    }
  }

  // Obtener jugadores por equipo
  List<Map<String, dynamic>> getPlayersByTeam(int team) {
    return _players.where((player) => player['team'] == team).toList();
  }

  // Obtener estadísticas de equipos
  Map<String, dynamic> getTeamsStats() {
    return {
      'team1Count': team1Count,
      'team2Count': team2Count,
      'unassignedCount': unassignedCount,
      'totalPlayers': _players.length,
      'isBalanced': (team1Count - team2Count).abs() <= 1,
    };
  }

  // Auto-balancear equipos (futura funcionalidad)
  void autoBalanceTeams() {
    // TODO: Implementar lógica de auto-balanceo
    // Por ahora solo notificamos
    notifyListeners();
  }

  // Limpiar todos los equipos
  void clearAllTeams() {
    for (var player in _players) {
      player['team'] = 0;
    }
    _updateTeamLists();
    notifyListeners();
  }

  // Actualizar listas de equipos internamente
  void _updateTeamLists() {
    _team1 = getPlayersByTeam(1);
    _team2 = getPlayersByTeam(2);
    _unassignedPlayers = getPlayersByTeam(0);
    
    print('🔄 _updateTeamLists - Team1: ${_team1.length} jugadores, Team2: ${_team2.length} jugadores');
    
    // Calcular promedios de skills para cada equipo
    _team1AverageSkills = calculateAverageSkills(_team1);
    _team2AverageSkills = calculateAverageSkills(_team2);
    
    print('📈 Team1 skills: $_team1AverageSkills');
    print('📈 Team2 skills: $_team2AverageSkills');
  }

  // Obtener URL completa de foto
  String getFullPhotoUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return '';
    
    if (photoUrl.startsWith('http')) {
      return photoUrl;
    } else {
      return '${ApiConfig.baseUrl}$photoUrl';
    }
  }

  // Calcular promedio de skills de una lista de jugadores
  Map<String, double> calculateAverageSkills(List<Map<String, dynamic>> players) {
    print('🔍 calculateAverageSkills - Jugadores recibidos: ${players.length}');
    
    if (players.isEmpty) {
      print('⚠️ calculateAverageSkills - Lista vacía, retornando ceros');
      return {
        'velocidad': 0.0,
        'resistencia': 0.0,
        'tiro_arco': 0.0,
        'gambeta': 0.0,
        'pases': 0.0,
        'defensa': 0.0,
      };
    }

    double totalVelocidad = 0.0;
    double totalResistencia = 0.0;
    double totalTiroArco = 0.0;
    double totalGambeta = 0.0;
    double totalPases = 0.0;
    double totalDefensa = 0.0;

    for (var player in players) {
      print('👤 Procesando jugador: ${player['name']} (ID: ${player['id']})');
      final averageSkills = player['averageSkills'] as Map<String, dynamic>?;
      print('📊 averageSkills del jugador: $averageSkills');
      
      if (averageSkills != null) {
        // Mapear de inglés (API) a español (hexágono)
        totalVelocidad += (averageSkills['speed'] ?? 0).toDouble();
        totalResistencia += (averageSkills['stamina'] ?? 0).toDouble();
        totalTiroArco += (averageSkills['shooting'] ?? 0).toDouble();
        totalGambeta += (averageSkills['dribbling'] ?? 0).toDouble();
        totalPases += (averageSkills['passing'] ?? 0).toDouble();
        totalDefensa += (averageSkills['defending'] ?? 0).toDouble();
        
        print('✅ Mapeo: speed=${averageSkills['speed']} → velocidad, stamina=${averageSkills['stamina']} → resistencia, shooting=${averageSkills['shooting']} → tiro_arco');
      } else {
        print('❌ Jugador ${player['name']} NO tiene averageSkills');
      }
    }

    final playerCount = players.length.toDouble();

    final result = {
      'velocidad': totalVelocidad / playerCount,
      'resistencia': totalResistencia / playerCount,
      'tiro_arco': totalTiroArco / playerCount,
      'gambeta': totalGambeta / playerCount,
      'pases': totalPases / playerCount,
      'defensa': totalDefensa / playerCount,
    };
    
    print('✅ calculateAverageSkills - Resultado final: $result');
    return result;
  }
}
