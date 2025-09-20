import 'package:flutter/material.dart';
import '../../models/network.dart';
import '../../models/player.dart';
import '../../services/fulbito/fulbito_players.dart';
import '../../services/fulbito/fulbito_registration.dart';

class FulbitoProvider with ChangeNotifier {
  Fulbito? _currentFulbito;
  bool _isLoading = false;
  String? _error;
  List<Player> _players = [];
  List<Player> _pendingAccept = [];
  List<Player> _enabledToRegister = [];
  List<Player> _rejected = [];
  Player? _selectedPlayer;
  bool _isAdmin = false;
  final FulbitoPlayersService _playersService = FulbitoPlayersService();
  final FulbitoRegistrationService _registrationService = FulbitoRegistrationService();

  // Getters
  Fulbito? get currentFulbito => _currentFulbito;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Player> get players => _players;
  List<Player> get pendingAccept => _pendingAccept;
  List<Player> get enabledToRegister => _enabledToRegister;
  List<Player> get rejected => _rejected;
  Player? get selectedPlayer => _selectedPlayer;
  bool get isAdmin => _isAdmin;

  // Cargar datos del fulbito
  Future<void> loadFulbitoDetails(Fulbito fulbito, String currentUserId, String token) async {
    print('🔍 [FulbitoProvider] Iniciando carga de detalles para fulbito: ${fulbito.id}');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentFulbito = fulbito;
      
      // Determinar si el usuario actual es admin (creador del fulbito)
      _isAdmin = fulbito.ownerPhone == currentUserId;
      
      print('🔍 [FulbitoProvider] Cargando jugadores desde API...');
      // Cargar jugadores reales desde la API
      final playersResponse = await _playersService.getFulbitoPlayers(token, fulbito.id);
      _players = playersResponse.players;
      _pendingAccept = playersResponse.pendingAccept;
      _enabledToRegister = playersResponse.enabledToRegister;
      _rejected = playersResponse.rejected;
      
      print('🔍 [FulbitoProvider] Jugadores cargados: ${_players.length}');
      print('🔍 [FulbitoProvider] PendingAccept: ${_pendingAccept.length}');
      print('🔍 [FulbitoProvider] EnabledToRegister: ${_enabledToRegister.length}');
      print('🔍 [FulbitoProvider] Rejected: ${_rejected.length}');
      
      // Cargar información de inscripción
      print('🔍 [FulbitoProvider] Cargando información de inscripción...');
      try {
        final registrationData = await _registrationService.getFulbitoRegistration(token, fulbito.id);
        print('🔍 [FulbitoProvider] Datos de inscripción: $registrationData');
        
        // Actualizar el fulbito con la información de inscripción
        if (registrationData['data'] != null) {
          final data = registrationData['data'] as Map<String, dynamic>;
          final updatedFulbito = Fulbito(
            id: fulbito.id,
            name: fulbito.name,
            place: fulbito.place,
            day: fulbito.day,
            hour: fulbito.hour,
            registrationStartDay: fulbito.registrationStartDay,
            registrationStartHour: fulbito.registrationStartHour,
            capacity: fulbito.capacity,
            ownerName: fulbito.ownerName,
            ownerPhone: fulbito.ownerPhone,
            ownerPhotoUrl: fulbito.ownerPhotoUrl,
            invitationId: fulbito.invitationId,
            message: fulbito.message,
            createdAt: fulbito.createdAt,
            updatedAt: fulbito.updatedAt,
            registrationStatus: RegistrationStatus.fromJson(data),
          );
          _currentFulbito = updatedFulbito;
          print('🔍 [FulbitoProvider] Fulbito actualizado con información de inscripción');
        }
      } catch (e) {
        print('🔍 [FulbitoProvider] Error cargando inscripción: $e');
        // No fallar si no se puede cargar la información de inscripción
      }
      
      // Seleccionar el primer jugador por defecto si hay jugadores
      if (_players.isNotEmpty) {
        _selectedPlayer = _players.first;
      }
      
      print('🔍 [FulbitoProvider] Detalles cargados exitosamente');
      
    } catch (e) {
      print('🔍 [FulbitoProvider] Error al cargar detalles: $e');
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
    _pendingAccept.clear();
    _enabledToRegister.clear();
    _rejected.clear();
    _selectedPlayer = null;
    _isAdmin = false;
    _error = null;
    notifyListeners();
  }
}
