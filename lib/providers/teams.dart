import 'package:flutter/material.dart';

class TeamsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _players = [];
  List<Map<String, dynamic>> _team1 = [];
  List<Map<String, dynamic>> _team2 = [];
  List<Map<String, dynamic>> _unassignedPlayers = [];

  // Getters
  List<Map<String, dynamic>> get players => _players;
  List<Map<String, dynamic>> get team1 => _team1;
  List<Map<String, dynamic>> get team2 => _team2;
  List<Map<String, dynamic>> get unassignedPlayers => _unassignedPlayers;
  
  int get team1Count => _team1.length;
  int get team2Count => _team2.length;
  int get unassignedCount => _unassignedPlayers.length;

  // Inicializar con jugadores registrados
  void initializeWithPlayers(List<Map<String, dynamic>> registeredPlayers) {
    _players = registeredPlayers.map((player) {
      return {
        'id': player['id'],
        'name': player['username'] ?? '',
        'photoUrl': player['photo_url'] ?? '',
        'team': 0, // Todos empiezan sin asignar
        'position': player['position'] ?? 0,
        'registeredAt': player['registered_at'] ?? '',
      };
    }).toList();
    
    _updateTeamLists();
    notifyListeners();
  }

  // Mover jugador a un equipo específico
  void movePlayerToTeam(int playerId, int team) {
    final playerIndex = _players.indexWhere((player) => player['id'] == playerId);
    if (playerIndex == -1) return;

    // Si el jugador ya está en ese equipo, lo removemos (vuelve a no asignado)
    if (_players[playerIndex]['team'] == team) {
      _players[playerIndex]['team'] = 0;
    } else {
      _players[playerIndex]['team'] = team;
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
  }

  // Obtener URL completa de foto
  String getFullPhotoUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return '';
    
    if (photoUrl.startsWith('http')) {
      return photoUrl;
    } else {
      return 'http://192.168.100.150:8000$photoUrl';
    }
  }
}
