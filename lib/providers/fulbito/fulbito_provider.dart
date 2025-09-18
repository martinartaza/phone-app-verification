import 'package:flutter/material.dart';
import '../../models/network.dart';
import '../../models/player.dart';
import '../../services/fulbito/fulbito_players.dart';

class FulbitoProvider with ChangeNotifier {
  Fulbito? _currentFulbito;
  bool _isLoading = false;
  String? _error;
  List<Player> _players = [];
  Player? _selectedPlayer;
  bool _isAdmin = false;
  final FulbitoPlayersService _playersService = FulbitoPlayersService();

  // Getters
  Fulbito? get currentFulbito => _currentFulbito;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Player> get players => _players;
  Player? get selectedPlayer => _selectedPlayer;
  bool get isAdmin => _isAdmin;

  // Cargar datos del fulbito
  Future<void> loadFulbitoDetails(Fulbito fulbito, String currentUserId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentFulbito = fulbito;
      
      // Determinar si el usuario actual es admin (creador del fulbito)
      _isAdmin = fulbito.ownerPhone == currentUserId;
      
      // Cargar jugadores reales desde la API
      final playersResponse = await _playersService.getFulbitoPlayers(token, fulbito.id);
      _players = playersResponse.players;
      
      // Seleccionar el primer jugador por defecto si hay jugadores
      if (_players.isNotEmpty) {
        _selectedPlayer = _players.first;
      }
      
    } catch (e) {
      _error = 'Error al cargar detalles del fulbito: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Seleccionar jugador para mostrar su hexágono
  void selectPlayer(Player player) {
    _selectedPlayer = player;
    notifyListeners();
  }

  // Limpiar selección
  void clearSelection() {
    _selectedPlayer = null;
    notifyListeners();
  }

  // Métodos para agregar/quitar jugadores (solo admin)
  void addPlayer(Player player) {
    if (_isAdmin && !_players.any((p) => p.id == player.id)) {
      _players.add(player);
      notifyListeners();
    }
  }

  void removePlayer(Player player) {
    if (_isAdmin) {
      _players.removeWhere((p) => p.id == player.id);
      notifyListeners();
    }
  }

  // Limpiar datos
  void clear() {
    _currentFulbito = null;
    _players.clear();
    _selectedPlayer = null;
    _isAdmin = false;
    _error = null;
    notifyListeners();
  }
}
