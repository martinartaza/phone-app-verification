import 'package:flutter/material.dart';
import '../models/network.dart';
import '../services/invitations.dart';
import '../services/invitation_status.dart';
import '../services/fulbito_status.dart';
import '../services/invite_player.dart';
import '../services/api_client.dart';
import '../widgets/maintenance_modal.dart';
import 'sync_provider.dart';

class InvitationsProvider with ChangeNotifier {
  final InvitationsService _service = InvitationsService();
  SyncProvider? _syncProvider;

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

  /// Configurar el SyncProvider para obtener datos de sincronización
  void setSyncProvider(SyncProvider syncProvider) {
    _syncProvider = syncProvider;
    // Escuchar cambios en el SyncProvider
    _syncProvider!.addListener(_onSyncDataChanged);
  }

  /// Callback cuando cambian los datos de sincronización
  void _onSyncDataChanged() {
    print('🔄 [InvitationsProvider] _onSyncDataChanged triggered');
    if (_syncProvider != null) {
      _updateDataFromSync();
    }
  }

  /// Actualizar datos desde el SyncProvider
  void _updateDataFromSync() {
    if (_syncProvider!.hasNetworkData) {
      // Convertir datos de sincronización a formato legacy
      final newNetworkData = _convertSyncNetworkData(_syncProvider!.networkData!);
      
      // Solo actualizar si hay datos reales (no vacíos)
      if (newNetworkData.network.isNotEmpty || newNetworkData.invitationPending.isNotEmpty) {
        _networkData = newNetworkData;
      }
    }
    
    if (_syncProvider!.hasFulbitosData) {
      // Convertir datos de sincronización a formato legacy
      final newFulbitosData = _convertSyncFulbitosData(_syncProvider!.fulbitosData!);
      
      // Solo actualizar si hay datos reales (no vacíos)
      if (newFulbitosData.myFulbitos.isNotEmpty || newFulbitosData.acceptFulbitos.isNotEmpty || newFulbitosData.pendingFulbitos.isNotEmpty) {
        _fulbitosData = newFulbitosData;
      }
    }
    
    // Limpiar cualquier error previo
    _error = null;
    _isLoading = false;
    
    notifyListeners();
  }

  /// Convertir SyncNetworkData a NetworkData (formato legacy)
  NetworkData _convertSyncNetworkData(dynamic syncNetworkData) {
    if (syncNetworkData == null) {
      return NetworkData(network: const [], invitationPending: const []);
    }

    try {
      final baseUrl = 'https://django.sebastianartaza.com';
      
      // Convertir conexiones aceptadas
      final connections = (syncNetworkData.connections as List<dynamic>)
          .map((json) => NetworkUser.fromSyncConnection(json, baseUrl))
          .toList();
      
      // Convertir invitaciones pendientes recibidas
      final pendingReceived = (syncNetworkData.pendingReceived as List<dynamic>)
          .map((json) => NetworkUser.fromSyncInvitation(json, baseUrl))
          .toList();
      
      return NetworkData(
        network: connections,
        invitationPending: pendingReceived,
      );
    } catch (e, stackTrace) {
      return NetworkData(network: const [], invitationPending: const []);
    }
  }

  /// Convertir SyncFulbitosData a FulbitosData (formato legacy)
  FulbitosData _convertSyncFulbitosData(dynamic syncFulbitosData) {
    if (syncFulbitosData == null) {
      return FulbitosData(myFulbitos: const [], acceptFulbitos: const [], pendingFulbitos: const []);
    }

    try {
      final baseUrl = 'https://django.sebastianartaza.com';

      List<Fulbito> mapListToFulbitos(List<dynamic> source, {bool isOwnerList = false}) {
        return source.map((item) {
          final map = item as Map<String, dynamic>;
          // Campos base del fulbito
          final id = map['id'] ?? 0;
          final name = map['name'] ?? '';
          final place = map['place'] ?? '';
          final day = map['day'] ?? (map['date'] ?? '');
          final hour = map['hour'] ?? (map['time'] ?? '');
          final registrationStartDay = map['registration_start_day'] ?? (map['registration_start_date'] ?? '');
          final registrationStartHour = map['registration_start_hour'] ?? (map['registration_start_time'] ?? '');
          final capacity = map['capacity'] ?? 0;
          final createdAt = map['created_at'] ?? '';
          final updatedAt = map['updated_at'] ?? '';

          // Dueño / organizador
          String ownerName = '';
          String ownerPhone = '';
          String? ownerPhotoUrl;

          if (map.containsKey('owner')) {
            final owner = map['owner'] as Map<String, dynamic>;
            ownerName = owner['username'] ?? owner['first_name'] ?? '';
            ownerPhone = owner['phone'] ?? '';
            final photoPath = owner['photo_url'] as String?;
            ownerPhotoUrl = (photoPath != null && photoPath.isNotEmpty)
                ? (photoPath.startsWith('http') ? photoPath : '$baseUrl$photoPath')
                : null;
          } else {
            // Compat: algunos objetos pueden venir como 'user' del creador
            final owner = map['user'] as Map<String, dynamic>?;
            if (owner != null) {
              ownerName = owner['username'] ?? owner['first_name'] ?? '';
              ownerPhone = owner['phone'] ?? '';
              final photoPath = owner['photo_url'] as String?;
              ownerPhotoUrl = (photoPath != null && photoPath.isNotEmpty)
                  ? (photoPath.startsWith('http') ? photoPath : '$baseUrl$photoPath')
                  : null;
            }
          }

          // Mensaje e invitación
          final message = map['message'];
          final invitationId = map['invitation_id'] ?? (map['id_invitation'] ?? null);

          // Estado de inscripción (opcional)
          RegistrationStatus? registrationStatus;
          if (map.containsKey('registration_status') && map['registration_status'] != null) {
            final rs = map['registration_status'] as Map<String, dynamic>;
            registrationStatus = RegistrationStatus.fromJson(rs);
          }

          return Fulbito(
            id: id,
            name: name,
            place: place,
            day: day,
            hour: hour,
            registrationStartDay: registrationStartDay,
            registrationStartHour: registrationStartHour,
            ownerName: ownerName,
            ownerPhone: ownerPhone,
            ownerPhotoUrl: ownerPhotoUrl,
            invitationId: isOwnerList ? null : invitationId,
            capacity: capacity,
            message: message,
            createdAt: createdAt,
            updatedAt: updatedAt,
            registrationStatus: registrationStatus,
          );
        }).toList();
      }

      final my = mapListToFulbitos(syncFulbitosData.myFulbitos as List<dynamic>, isOwnerList: true);
      final member = mapListToFulbitos(syncFulbitosData.memberFulbitos as List<dynamic>);
      final pending = mapListToFulbitos(syncFulbitosData.pendingInvitations as List<dynamic>);

      return FulbitosData(
        myFulbitos: my,
        acceptFulbitos: member,
        pendingFulbitos: pending,
        nextEvent: syncFulbitosData.nextCriticalEventSeconds,
      );
    } catch (e, stackTrace) {
      print('❌ [InvitationsProvider] Error converting fulbitos data: $e');
      print('❌ Stack trace: $stackTrace');
      return FulbitosData(myFulbitos: const [], acceptFulbitos: const [], pendingFulbitos: const []);
    }
  }

  Future<void> load(String token) async {
    // Si tenemos SyncProvider, usar datos de sincronización
    if (_syncProvider != null) {
      _updateDataFromSync();
      return;
    }

    // Si no hay SyncProvider, inicializar con datos vacíos para evitar errores
    print('⚠️ [InvitationsProvider] No SyncProvider configured, using empty data');
    _networkData = NetworkData(network: const [], invitationPending: const []);
    _fulbitosData = FulbitosData(myFulbitos: const [], acceptFulbitos: const [], pendingFulbitos: const []);
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Acepta una invitación de red usando API v2
  Future<bool> acceptInvitation(String token, int invitationId) async {
    try {
      print('🌐 [InvitationsProvider] Accepting network invitation: $invitationId');
      
      // Crear ApiClient con callback de sync automático
      final apiClient = ApiClient(
        token: token,
        onSyncRequired: _syncProvider != null
            ? (token) => _syncProvider!.performIncrementalSync(token)
            : null,
      );
      
      // Usar el nuevo servicio de API v2 con ApiClient
      final success = await InvitePlayerService.acceptConnection(
        token: token,
        connectionId: invitationId,
        apiClient: apiClient,
      );

      if (success) {
        print('✅ [InvitationsProvider] Connection accepted successfully');
        // Sync se disparó automáticamente en ApiClient
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
      
      // Crear ApiClient con callback de sync automático
      final apiClient = ApiClient(
        token: token,
        onSyncRequired: _syncProvider != null
            ? (token) => _syncProvider!.performIncrementalSync(token)
            : null,
      );
      
      // Usar el nuevo servicio de API v2 con ApiClient
      final success = await InvitePlayerService.rejectConnection(
        token: token,
        connectionId: invitationId,
        apiClient: apiClient,
      );

      if (success) {
        print('✅ [InvitationsProvider] Connection rejected successfully');
        // Sync se disparó automáticamente en ApiClient
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

  @override
  void dispose() {
    // Limpiar listener del SyncProvider
    _syncProvider?.removeListener(_onSyncDataChanged);
    super.dispose();
  }
}

