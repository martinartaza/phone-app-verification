import 'package:flutter/material.dart';
import '../models/network.dart';
import '../services/invitations.dart';
import '../services/invitation_status.dart';
import '../services/fulbito_status.dart';
import '../services/invite_player.dart';
import '../widgets/maintenance_modal.dart';

class InvitationsProvider with ChangeNotifier {
  final InvitationsService _service = InvitationsService();

  bool _isLoading = false;
  String? _error;
  NetworkData _networkData = NetworkData(network: const [], invitationPending: const []);
  FulbitosData _fulbitosData = FulbitosData(myFulbitos: const [], acceptFulbitos: const [], pendingFulbitos: const []);

  bool get isLoading => _isLoading;
  String? get error => _error;
  NetworkData get networkData => _networkData;
  FulbitosData get fulbitosData => _fulbitosData;

  bool get isNetworkEmpty => _networkData.network.isEmpty && _networkData.invitationPending.isEmpty;
  bool get isFulbitosEmpty => _fulbitosData.isEmpty;

  Future<void> load(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.fetchAllData(token);
      _networkData = data.networkData;
      _fulbitosData = data.fulbitosData;
    } catch (e) {
      if (e.toString().contains('MAINTENANCE_MODE')) {
        _error = 'MAINTENANCE_MODE';
      } else {
        _error = 'Error al cargar datos';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Acepta una invitación de red usando API v2
  Future<bool> acceptInvitation(String token, int invitationId) async {
    try {
      print('🌐 [InvitationsProvider] Accepting network invitation: $invitationId');
      
      // Usar el nuevo servicio de API v2
      final success = await InvitePlayerService.acceptConnection(
        token: token,
        connectionId: invitationId,
      );

      if (success) {
        print('✅ [InvitationsProvider] Connection accepted successfully');
        // Recargar los datos para reflejar el cambio
        await load(token);
        return true;
      } else {
        print('❌ [InvitationsProvider] Failed to accept connection');
        _error = 'Error al aceptar invitación';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ [InvitationsProvider] Error accepting invitation: $e');
      _error = 'Error al aceptar invitación: $e';
      notifyListeners();
      return false;
    }
  }

  /// Rechaza una invitación de red usando API v2
  Future<bool> rejectInvitation(String token, int invitationId) async {
    try {
      print('🌐 [InvitationsProvider] Rejecting network invitation: $invitationId');
      
      // Usar el nuevo servicio de API v2
      final success = await InvitePlayerService.rejectConnection(
        token: token,
        connectionId: invitationId,
      );

      if (success) {
        print('✅ [InvitationsProvider] Connection rejected successfully');
        // Recargar los datos para reflejar el cambio
        await load(token);
        return true;
      } else {
        print('❌ [InvitationsProvider] Failed to reject connection');
        _error = 'Error al rechazar invitación';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ [InvitationsProvider] Error rejecting invitation: $e');
      _error = 'Error al rechazar invitación: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptFulbito(String token, int invitationId) async {
    try {
      final result = await FulbitoStatusService.updateFulbitoStatus(
        token: token,
        invitationId: invitationId,
        status: 'accepted',
      );

      if (result['success']) {
        // Recargar los datos para reflejar el cambio
        await load(token);
        return true;
      } else {
        _error = result['error'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error al aceptar fulbito: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectFulbito(String token, int invitationId) async {
    try {
      final result = await FulbitoStatusService.updateFulbitoStatus(
        token: token,
        invitationId: invitationId,
        status: 'rejected',
      );

      if (result['success']) {
        // Recargar los datos para reflejar el cambio
        await load(token);
        return true;
      } else {
        _error = result['error'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error al rechazar fulbito: $e';
      notifyListeners();
      return false;
    }
  }

  // Métodos de conveniencia para manejar acciones desde la UI
  Future<Map<String, dynamic>> handleAcceptInvitation(String token, int invitationId, BuildContext context) async {
    try {
      final success = await acceptInvitation(token, invitationId);
      
      if (!success && error == 'MAINTENANCE_MODE') {
        MaintenanceModal.show(context, onRetry: () => load(token));
        return {
          'success': false,
          'message': 'Modo mantenimiento',
          'isError': false, // No es un error, es modo mantenimiento
        };
      }
      
      return {
        'success': success,
        'message': success ? 'Invitación aceptada' : (error ?? 'Error al aceptar invitación'),
        'isError': !success,
      };
    } catch (e) {
      MaintenanceModal.show(context, onRetry: () => load(token));
      return {
        'success': false,
        'message': 'Modo mantenimiento',
        'isError': false, // No es un error, es modo mantenimiento
      };
    }
  }

  Future<Map<String, dynamic>> handleRejectInvitation(String token, int invitationId, BuildContext context) async {
    try {
      final success = await rejectInvitation(token, invitationId);
      
      if (!success && error == 'MAINTENANCE_MODE') {
        MaintenanceModal.show(context, onRetry: () => load(token));
        return {
          'success': false,
          'message': 'Modo mantenimiento',
          'isError': false,
        };
      }
      
      return {
        'success': success,
        'message': success ? 'Invitación rechazada' : (error ?? 'Error al rechazar invitación'),
        'isError': !success,
      };
    } catch (e) {
      MaintenanceModal.show(context, onRetry: () => load(token));
      return {
        'success': false,
        'message': 'Modo mantenimiento',
        'isError': false,
      };
    }
  }

  Future<Map<String, dynamic>> handleAcceptFulbito(String token, int invitationId, BuildContext context) async {
    try {
      final success = await acceptFulbito(token, invitationId);
      
      if (!success && error == 'MAINTENANCE_MODE') {
        MaintenanceModal.show(context, onRetry: () => load(token));
        return {
          'success': false,
          'message': 'Modo mantenimiento',
          'isError': false,
        };
      }
      
      return {
        'success': success,
        'message': success ? 'Fulbito aceptado' : (error ?? 'Error al aceptar fulbito'),
        'isError': !success,
      };
    } catch (e) {
      MaintenanceModal.show(context, onRetry: () => load(token));
      return {
        'success': false,
        'message': 'Modo mantenimiento',
        'isError': false,
      };
    }
  }

  Future<Map<String, dynamic>> handleRejectFulbito(String token, int invitationId, BuildContext context) async {
    try {
      final success = await rejectFulbito(token, invitationId);
      
      if (!success && error == 'MAINTENANCE_MODE') {
        MaintenanceModal.show(context, onRetry: () => load(token));
        return {
          'success': false,
          'message': 'Modo mantenimiento',
          'isError': false,
        };
      }
      
      return {
        'success': success,
        'message': success ? 'Fulbito rechazado' : (error ?? 'Error al rechazar fulbito'),
        'isError': !success,
      };
    } catch (e) {
      MaintenanceModal.show(context, onRetry: () => load(token));
      return {
        'success': false,
        'message': 'Modo mantenimiento',
        'isError': false,
      };
    }
  }
}

