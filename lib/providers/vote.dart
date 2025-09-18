import 'package:flutter/material.dart';
import '../models/network.dart';
import '../models/player_details.dart';
import '../services/vote.dart';

class VoteProvider extends ChangeNotifier {
  final VoteService _voteService = VoteService();
  
  // Estado del provider
  PlayerDetails? _playerDetails;
  bool _isLoading = false;
  String? _error;
  
  // Votación del usuario (empieza en 50 para todas las habilidades)
  final Map<String, double> _userVote = {
    'velocidad': 50.0,
    'resistencia': 50.0,
    'tiro_arco': 50.0,
    'gambeta': 50.0,
    'pases': 50.0,
    'defensa': 50.0,
  };

  // Getters
  PlayerDetails? get playerDetails => _playerDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, double> get userVote => Map.from(_userVote);

  // Cargar datos del jugador
  Future<void> loadPlayerDetails(String token, String playerUuid) async {
    _setLoading(true);
    _clearError();

    try {
      final playerDetails = await _voteService.getPlayerDetails(token, playerUuid);
      _playerDetails = playerDetails;
      if (playerDetails == null) {
        _setError('No se pudieron cargar los datos del jugador');
      }
    } catch (e) {
      _setError('Error al cargar los datos del jugador');
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar votación del usuario
  void updateVote(String skill, double value) {
    _userVote[skill] = value;
    notifyListeners();
  }

  // Enviar votación
  Future<bool> submitVote(String token, String playerUuid) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _voteService.submitVote(token, playerUuid, _userVote);
      if (!success) {
        _setError('Error al enviar la votación');
      }
      return success;
    } catch (e) {
      _setError('Error al enviar la votación');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Limpiar estado
  void clearState() {
    _playerDetails = null;
    _isLoading = false;
    _error = null;
    // Resetear votación a valores por defecto
    _userVote.updateAll((key, value) => 50.0);
    notifyListeners();
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
