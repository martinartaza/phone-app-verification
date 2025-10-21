import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/player.dart';
import '../../services/invite_player.dart';
import '../../config/api_config.dart';
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
      // Obtener IDs de los jugadores seleccionados directamente
      final List<int> selectedPlayerIds = _selectedPlayers.toList();

      print('🔍 [InvitePlayersProvider] Enviando invitaciones a ${selectedPlayerIds.length} usuarios: $selectedPlayerIds');

      // Usar el nuevo endpoint que acepta múltiples user_ids
      final result = await _sendInvitationsV2(
        token: token,
        fulbitoId: fulbitoId,
        userIds: selectedPlayerIds,
        message: _invitationMessage,
      );

      if (result['success'] == true) {
        print('✅ [InvitePlayersProvider] Invitaciones enviadas exitosamente');
        clearSelection();
        _setLoading(false);
        return true;
      } else {
        _setError(result['error'] ?? 'Error al enviar invitaciones');
        _setLoading(false);
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

  /// Enviar invitaciones usando el nuevo endpoint v2
  Future<Map<String, dynamic>> _sendInvitationsV2({
    required String token,
    required int fulbitoId,
    required List<int> userIds,
    required String message,
  }) async {
    try {
      print('🌐 API CALL - POST ${ApiConfig.getFulbitoInviteListUrl(fulbitoId)}');
      print('🌐 Headers: Authorization: Bearer $token');
      print('🌐 Body: {players_user_id: $userIds, message: $message}');

      final response = await http.post(
        Uri.parse(ApiConfig.getFulbitoInviteListUrl(fulbitoId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'players_user_id': userIds,  // Array de user_ids
          'message': message,
        }),
      );

      print('🌐 Response Status: ${response.statusCode}');
      print('🌐 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Invitaciones enviadas exitosamente a ${userIds.length} usuarios');
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final responseData = jsonDecode(response.body);
        final error = responseData['message'] ?? 'Error al enviar invitaciones';
        print('❌ Error enviando invitaciones: $error');
        return {
          'success': false,
          'error': error,
        };
      }
    } catch (e) {
      print('❌ Error sending invitations v2: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }
}
