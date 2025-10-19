import 'package:flutter/material.dart';
import '../../models/network.dart';
import '../../models/player.dart';
import '../../services/fulbito/fulbito_players.dart';
import '../../services/fulbito/fulbito_registration.dart';
import '../../services/fulbito/fulbito_details.dart';
import '../sync_provider.dart';

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
  
  // Referencia al SyncProvider para usar datos en memoria
  SyncProvider? _syncProvider;

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

  /// Configurar el SyncProvider para usar datos en memoria
  void setSyncProvider(SyncProvider syncProvider) {
    _syncProvider = syncProvider;
    print('✅ [FulbitoProvider] SyncProvider configurado');
  }

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
      
      // Intentar usar datos del SyncProvider primero
      if (_syncProvider != null && _syncProvider!.hasFulbitosData) {
        print('🔍 [FulbitoProvider] ✅ Usando datos del SyncProvider (en memoria)');
        // Guardar el token en el SyncProvider para usar en la llamada API
        _syncProvider!.setToken(token);
        await _loadFromSyncProvider(fulbito);
      } else {
        print('🔍 [FulbitoProvider] ❌ SyncProvider no disponible, usando APIs viejas...');
        await _loadFromOldAPI(token, fulbito);
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

  /// Cargar datos desde SyncProvider (datos en memoria)
  Future<void> _loadFromSyncProvider(Fulbito fulbito) async {
    print('🔍 [FulbitoProvider] Cargando desde SyncProvider...');
    
    // Hacer llamada a la API de detalles del fulbito para obtener jugadores
    print('🔍 [FulbitoProvider] Obteniendo detalles del fulbito desde API...');
    final detailsResponse = await FulbitoDetailsService.getFulbitoDetails(
      token: _syncProvider!.token ?? '',
      fulbitoId: fulbito.id,
    );
    
    if (detailsResponse != null && detailsResponse['status'] == 'success') {
      final data = detailsResponse['data'] as Map<String, dynamic>;
      final playersData = data['players'] as List<dynamic>? ?? [];
      
      print('🔍 [FulbitoProvider] Procesando ${playersData.length} jugadores del fulbito...');
      
      // Convertir jugadores del fulbito
      _players = playersData.map<Player>((playerData) {
        final skills = _parseAverageSkills(playerData['average_skills']);
        print('🔍 [FulbitoProvider] Jugador ${playerData['username']}:');
        print('🔍 [FulbitoProvider] Raw skills: ${playerData['average_skills']}');
        print('🔍 [FulbitoProvider] Parsed skills: $skills');
        
        return Player(
          id: playerData['id'] ?? 0,
          username: playerData['username'] ?? '',
          phone: playerData['phone'] ?? '',
          photoUrl: playerData['photo_url'] != null && playerData['photo_url'].toString().isNotEmpty
              ? (playerData['photo_url'].toString().startsWith('http') 
                  ? playerData['photo_url'].toString() 
                  : 'https://django.sebastianartaza.com${playerData['photo_url']}')
              : null,
          typePlayer: playerData['role'] ?? 'player',
          type: playerData['membership_type'] ?? 'regular',
          averageSkills: skills,
        );
      }).toList();
      
      print('🔍 [FulbitoProvider] ✅ ${_players.length} jugadores cargados del fulbito');
    } else {
      print('🔍 [FulbitoProvider] ⚠️ No se pudieron obtener detalles del fulbito');
      _players = [];
    }
    
    // Usar datos de red del SyncProvider para jugadores disponibles para invitar
    if (_syncProvider!.hasNetworkData) {
      final networkData = _syncProvider!.networkData!;
      print('🔍 [FulbitoProvider] Convirtiendo ${networkData.connections.length} conexiones a jugadores disponibles...');
      
      // Convertir conexiones de red a jugadores disponibles para invitar
      _enabledToRegister = networkData.connections.map<Player>((connection) {
        final user = connection['user'] as Map<String, dynamic>;
        return Player(
          id: user['id'] ?? 0,
          username: user['username'] ?? '',
          phone: user['phone'] ?? '',
          photoUrl: user['photo_url'] != null && user['photo_url'].toString().isNotEmpty
              ? (user['photo_url'].toString().startsWith('http') 
                  ? user['photo_url'].toString() 
                  : 'https://django.sebastianartaza.com${user['photo_url']}')
              : null,
          typePlayer: 'player', // Tipo de jugador por defecto
          type: 'player', // Tipo por defecto
          averageSkills: const {}, // Por ahora vacío
        );
      }).toList();
      
      print('🔍 [FulbitoProvider] ✅ ${_enabledToRegister.length} jugadores disponibles para invitar');
    } else {
      print('🔍 [FulbitoProvider] ⚠️ No hay datos de red en SyncProvider');
      _enabledToRegister = [];
    }
    
    // Por ahora, las otras listas están vacías
    _pendingAccept = [];
    _rejected = [];
    
    print('🔍 [FulbitoProvider] Datos cargados desde SyncProvider');
  }

  /// Parsear habilidades promedio del jugador
  Map<String, double> _parseAverageSkills(dynamic skills) {
    print('🔍 [FulbitoProvider] _parseAverageSkills input: $skills');
    print('🔍 [FulbitoProvider] Type: ${skills.runtimeType}');
    
    if (skills == null || skills is! Map<String, dynamic>) {
      print('🔍 [FulbitoProvider] Skills is null or not a Map, returning empty');
      return {};
    }
    
    // Mapeo de nombres de habilidades de inglés a español
    final Map<String, String> skillNameMapping = {
      'speed': 'velocidad',
      'stamina': 'resistencia', 
      'shooting': 'tiro_arco',
      'dribbling': 'gambeta',
      'passing': 'pases',
      'defending': 'defensa',
    };
    
    final Map<String, double> result = {};
    skills.forEach((key, value) {
      print('🔍 [FulbitoProvider] Processing skill: $key = $value (${value.runtimeType})');
      if (value is num) {
        // Mapear el nombre de la habilidad al nombre esperado por el widget
        final mappedKey = skillNameMapping[key] ?? key;
        result[mappedKey] = value.toDouble();
        print('🔍 [FulbitoProvider] Added skill: $key -> $mappedKey = ${result[mappedKey]}');
      } else {
        print('🔍 [FulbitoProvider] Skipped skill: $key (not a number)');
      }
    });
    
    print('🔍 [FulbitoProvider] Final parsed skills: $result');
    return result;
  }

  /// Cargar datos desde APIs viejas (fallback)
  Future<void> _loadFromOldAPI(String token, Fulbito fulbito) async {
    print('🔍 [FulbitoProvider] Cargando jugadores desde API VIEJA...');
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
    print('🔍 [FulbitoProvider] Cargando información de inscripción desde API VIEJA...');
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
