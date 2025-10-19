import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../services/invite_player.dart';
import '../sync_provider.dart';

class InvitePlayersProvider with ChangeNotifier {
  // Estado del provider
  Set<int> _selectedPlayers = {}; // IDs de jugadores seleccionados
  bool _isLoading = false;
  String? _error;
  String _invitationMessage = '';
  
  // Referencia al SyncProvider para obtener user_id de phone_numbers
  SyncProvider? _syncProvider;

  // Getters
  Set<int> get selectedPlayers => Set.from(_selectedPlayers);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get invitationMessage => _invitationMessage;
  bool get hasSelectedPlayers => _selectedPlayers.isNotEmpty;

  /// Configurar el SyncProvider
  void setSyncProvider(SyncProvider syncProvider) {
    _syncProvider = syncProvider;
    print('✅ [InvitePlayersProvider] SyncProvider configurado');
  }

  // Seleccionar/deseleccionar jugador
  void togglePlayerSelection(int playerId) {
    if (_selectedPlayers.contains(playerId)) {
      _selectedPlayers.remove(playerId);
    } else {
      _selectedPlayers.add(playerId);
    }
    notifyListeners();
  }

  // Verificar si un jugador está seleccionado
  bool isPlayerSelected(int playerId) {
    return _selectedPlayers.contains(playerId);
  }

  // Actualizar mensaje de invitación
  void updateInvitationMessage(String message) {
    _invitationMessage = message;
    notifyListeners();
  }

  // Enviar invitaciones
  Future<bool> sendInvitations({
    required String token,
    required int fulbitoId,
    required List<Player> allPlayers,
  }) async {
    if (_selectedPlayers.isEmpty) return false;

    _setLoading(true);
    _clearError();

    try {
      // Obtener números de teléfono de los jugadores seleccionados
      final List<String> phoneNumbers = [];
      for (final player in allPlayers) {
        if (_selectedPlayers.contains(player.id)) {
          phoneNumbers.add(player.phone);
        }
      }

      if (phoneNumbers.isEmpty) {
        _setError('No se encontraron números de teléfono');
        return false;
      }

      // Llamar a la API
      final result = await InvitePlayerService.inviteToFulbito(
        token: token,
        fulbitoId: fulbitoId,
        phoneNumbers: phoneNumbers,
      );

      if (result['success']) {
        // Limpiar selección después del envío exitoso
        clearSelection();
        return true;
      } else {
        _setError(result['error'] ?? 'Error al enviar invitaciones');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Limpiar selección
  void clearSelection() {
    _selectedPlayers.clear();
    notifyListeners();
  }

  // Limpiar estado completo
  void clearState() {
    _selectedPlayers.clear();
    _isLoading = false;
    _error = null;
    _invitationMessage = '';
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
