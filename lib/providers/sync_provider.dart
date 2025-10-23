import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';
import '../models/sync_models.dart';
import '../services/storage.dart' as storage_service;

class SyncProvider with ChangeNotifier {
  // Estado de sincronización
  bool _isLoading = false;
  bool _isInitialLoad = false;
  String? _error;
  
  // Datos de sincronización
  String? _currentEtag;
  String? _lastSyncTimestamp;
  SyncVersion? _version;
  
  // Polling dinámico
  Timer? _pollingTimer;
  bool _isPollingActive = false;
  SyncPollingInfo? _currentPollingInfo;
  
  // Datos sincronizados
  SyncNetworkData? _networkData;
  SyncFulbitosData? _fulbitosData;
  SyncNotificationsData? _notificationsData;
  
  // Token para llamadas API
  String? _token;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isInitialLoad => _isInitialLoad;
  String? get error => _error;
  String? get currentEtag => _currentEtag;
  String? get lastSyncTimestamp => _lastSyncTimestamp;
  SyncVersion? get version => _version;
  bool get isPollingActive => _isPollingActive;
  SyncPollingInfo? get currentPollingInfo => _currentPollingInfo;
  
  SyncNetworkData? get networkData => _networkData;
  SyncFulbitosData? get fulbitosData => _fulbitosData;
  SyncNotificationsData? get notificationsData => _notificationsData;
  
  // Getters de conveniencia
  bool get hasNetworkData => _networkData != null;
  bool get hasFulbitosData => _fulbitosData != null;
  bool get hasNotificationsData => _notificationsData != null;
  
  int get totalNotifications => _notificationsData?.total ?? 0;
  int get networkNotifications => _notificationsData?.network ?? 0;
  int get fulbitoNotifications => _notificationsData?.fulbito ?? 0;
  
  String? get token => _token;

  /// Configurar token para llamadas API
  void setToken(String token) {
    _token = token;
    print('✅ [SyncProvider] Token configurado');
  }

  /// Carga inicial completa - Todas las páginas
  Future<bool> performInitialSync(String token) async {
    _setLoading(true, isInitialLoad: true);
    _clearError();

    try {
      print('🔄 [SyncProvider] Starting initial sync...');
      
      // Cargar todas las páginas
      final result = await SyncService.loadAllInitialPages(token: token);
      
      if (result.pages.isEmpty) {
        _setError('No se pudieron cargar datos iniciales');
        return false;
      }

      // Guardar ETag y lastUpdate del resultado
      _currentEtag = result.etag;
      _lastSyncTimestamp = result.lastUpdate;

      // Procesar todas las páginas
      await _processInitialPages(result.pages);
      
      // Guardar estado de sincronización
      await _saveSyncState();
      
      // Configurar polling inicial
      if (result.pages.isNotEmpty) {
        final lastPage = result.pages.last;
        final pollingInfo = SyncService.extractPollingInfo(lastPage);
        await _setupPolling(pollingInfo);
      }
      
      print('✅ [SyncProvider] Initial sync completed successfully');
      return true;
      
    } catch (e) {
      print('❌ [SyncProvider] Initial sync failed: $e');
      _setError('Error en sincronización inicial: $e');
      return false;
    } finally {
      _setLoading(false, isInitialLoad: false);
    }
  }

  /// Sincronización incremental
  Future<bool> performIncrementalSync(String token) async {
    if (_isLoading) return false;
    
    _setLoading(true);
    _clearError();

    try {
      print('🔄 [SyncProvider] Starting incremental sync...');
      print('🔄 [SyncProvider] ETag: $_currentEtag');
      print('🔄 [SyncProvider] Last Sync: $_lastSyncTimestamp');
      
      final result = await SyncService.syncIncremental(
        token: token,
        lastSync: _lastSyncTimestamp,
        etag: _currentEtag,
      );
      
      if (result != null) {
        print('🔍 [SyncProvider] Sync result received, processing...');
        print('🔍 [SyncProvider] Result response: ${result.response}');
        
        // Procesar datos
        await _processSyncResponse(result.response);
        
        // Actualizar ETag y lastUpdate SOLAMENTE tras sync
        if (result.etag != null && result.etag!.isNotEmpty) {
          _currentEtag = result.etag;
        }
        if (result.lastUpdate != null && result.lastUpdate!.isNotEmpty) {
          _lastSyncTimestamp = result.lastUpdate;
        }
        
        await _saveSyncState();
        
        // Actualizar polling si es necesario
        final pollingInfo = SyncService.extractPollingInfo(result.response);
        await _updatePolling(pollingInfo);
        
        print('✅ [SyncProvider] Incremental sync completed successfully');
        return true;
      } else {
        _setError('Error en sincronización incremental');
        return false;
      }
      
    } catch (e) {
      print('❌ [SyncProvider] Incremental sync failed: $e');
      _setError('Error en sincronización incremental: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Procesar páginas de carga inicial
  Future<void> _processInitialPages(List<SyncResponse> pages) async {
    print('🔄 [SyncProvider] Processing ${pages.length} initial pages...');
    
    for (final page in pages) {
      await _processSyncResponse(page);
    }
    
    print('✅ [SyncProvider] All initial pages processed');
  }

  /// Procesar respuesta de sincronización
  Future<void> _processSyncResponse(SyncResponse response) async {
    print('🔍 [SyncProvider] _processSyncResponse called');
    print('🔍 [SyncProvider] Response status: ${response.status}');
    print('🔍 [SyncProvider] Has data: ${response.hasData}');
    print('🔍 [SyncProvider] Data: ${response.data}');
    
    // Actualizar versión y timestamps
    _version = response.version;
    _lastSyncTimestamp = response.lastUpdate;
    
    // Procesar datos de red
    if (response.hasData && response.data!.network != null) {
      if (_networkData == null) {
        _networkData = response.data!.network!;
      } else {
        // UPSERT: Actualizar o agregar conexiones
        for (final newConnection in response.data!.network!.connections) {
          final connectionId = newConnection['connection_id'];
          final existingIndex = _networkData!.connections.indexWhere(
            (existing) => existing['connection_id'] == connectionId
          );
          
          if (existingIndex >= 0) {
            // Actualizar conexión existente
            _networkData!.connections[existingIndex] = newConnection;
          } else {
            // Agregar nueva conexión
            _networkData!.connections.add(newConnection);
          }
        }
        
        // UPSERT: Actualizar o agregar pending received
        for (final newPending in response.data!.network!.pendingReceived) {
          final userId = newPending['user']?['id'];
          final existingIndex = _networkData!.pendingReceived.indexWhere(
            (existing) => existing['user']?['id'] == userId
          );
          
          if (existingIndex >= 0) {
            _networkData!.pendingReceived[existingIndex] = newPending;
          } else {
            _networkData!.pendingReceived.add(newPending);
          }
        }
        
        // UPSERT: Actualizar o agregar pending sent
        for (final newPending in response.data!.network!.pendingSent) {
          final userId = newPending['user']?['id'];
          final existingIndex = _networkData!.pendingSent.indexWhere(
            (existing) => existing['user']?['id'] == userId
          );
          
          if (existingIndex >= 0) {
            _networkData!.pendingSent[existingIndex] = newPending;
          } else {
            _networkData!.pendingSent.add(newPending);
          }
        }
      }
      print('🔄 [SyncProvider] Network data updated: ${_networkData!.totalConnections} connections');
      
      // Guardar network data localmente
      await _saveNetworkData();
    } else {
      print('❌ [SyncProvider] No network data in sync response');
    }
    
    // Procesar datos de fulbitos
    if (response.hasData && response.data!.fulbitos != null) {
      if (_fulbitosData == null) {
        _fulbitosData = response.data!.fulbitos!;
      } else {
        // UPSERT: Actualizar o agregar myFulbitos
        for (final newFulbito in response.data!.fulbitos!.myFulbitos) {
          final fulbitoId = newFulbito['id'];
          final existingIndex = _fulbitosData!.myFulbitos.indexWhere(
            (existing) => existing['id'] == fulbitoId
          );
          
          if (existingIndex >= 0) {
            // Actualizar fulbito existente
            _fulbitosData!.myFulbitos[existingIndex] = newFulbito;
            print('🔄 [SyncProvider] Updated myFulbito: $fulbitoId');
          } else {
            // Agregar nuevo fulbito
            _fulbitosData!.myFulbitos.add(newFulbito);
            print('➕ [SyncProvider] Added new myFulbito: $fulbitoId');
          }
        }
        
        // UPSERT: Actualizar o agregar memberFulbitos
        for (final newFulbito in response.data!.fulbitos!.memberFulbitos) {
          final fulbitoId = newFulbito['id'];
          final existingIndex = _fulbitosData!.memberFulbitos.indexWhere(
            (existing) => existing['id'] == fulbitoId
          );
          
          if (existingIndex >= 0) {
            // Actualizar fulbito existente
            _fulbitosData!.memberFulbitos[existingIndex] = newFulbito;
            print('🔄 [SyncProvider] Updated memberFulbito: $fulbitoId');
          } else {
            // Agregar nuevo fulbito
            _fulbitosData!.memberFulbitos.add(newFulbito);
            print('➕ [SyncProvider] Added new memberFulbito: $fulbitoId');
          }
        }
      }
      print('🔄 [SyncProvider] Fulbitos data updated: ${_fulbitosData!.totalMyFulbitos} my fulbitos');
      
      // DEBUG: Ver qué datos están llegando del sync
      print('🔍 [SyncProvider] DEBUG - Fulbitos data:');
      print('  - myFulbitos: ${_fulbitosData!.myFulbitos}');
      print('  - memberFulbitos: ${_fulbitosData!.memberFulbitos}');
      
      // DEBUG: Verificar si hay userRegistered en los fulbitos
      for (int i = 0; i < _fulbitosData!.myFulbitos.length; i++) {
        final fulbito = _fulbitosData!.myFulbitos[i];
        print('🔍 [SyncProvider] DEBUG - MyFulbito $i:');
        print('  - id: ${fulbito['id']}');
        print('  - registration_status: ${fulbito['registration_status']}');
        if (fulbito['registration_status'] != null) {
          print('  - user_registered: ${fulbito['registration_status']['user_registered']}');
        }
      }
      
      // Guardar fulbitos data localmente
      await _saveFulbitosData();
    }
    
    // Procesar notificaciones
    if (response.hasData && response.data!.notifications != null) {
      _notificationsData = response.data!.notifications!;
      print('🔄 [SyncProvider] Notifications updated: ${_notificationsData!.total} total');
    }
    
    notifyListeners();
  }

  /// Guardar network data localmente
  Future<void> _saveNetworkData() async {
    if (_networkData != null) {
      try {
        await storage_service.StorageService.saveNetworkData(_networkData!.toJson());
        print('💾 [SyncProvider] Network data saved to storage');
      } catch (e) {
        print('❌ [SyncProvider] Error saving network data: $e');
      }
    }
  }

  /// Guardar fulbitos data localmente
  Future<void> _saveFulbitosData() async {
    if (_fulbitosData != null) {
      try {
        await storage_service.StorageService.saveFulbitosData(_fulbitosData!.toJson());
        print('💾 [SyncProvider] Fulbitos data saved to storage');
      } catch (e) {
        print('❌ [SyncProvider] Error saving fulbitos data: $e');
      }
    }
  }

  /// Configurar polling dinámico
  Future<void> _setupPolling(SyncPollingInfo pollingInfo) async {
    _currentPollingInfo = pollingInfo;
    
    if (pollingInfo.needsPolling) {
      await _startPolling(pollingInfo.pollingIntervalSeconds);
    } else {
      await _stopPolling();
    }
  }

  /// Actualizar configuración de polling
  Future<void> _updatePolling(SyncPollingInfo pollingInfo) async {
    final previousInfo = _currentPollingInfo;
    _currentPollingInfo = pollingInfo;
    
    // Solo reiniciar polling si cambió la configuración
    if (previousInfo == null || 
        previousInfo.pollingIntervalSeconds != pollingInfo.pollingIntervalSeconds ||
        previousInfo.needsPolling != pollingInfo.needsPolling) {
      
      if (pollingInfo.needsPolling) {
        await _startPolling(pollingInfo.pollingIntervalSeconds);
      } else {
        await _stopPolling();
      }
      
      print('🔄 [SyncProvider] Polling updated: ${pollingInfo.pollingIntervalSeconds}s (${pollingInfo.reason})');
    }
  }

  /// Iniciar polling con intervalo específico
  Future<void> _startPolling(int intervalSeconds) async {
    await _stopPolling(); // Parar cualquier polling anterior
    
    _isPollingActive = true;
    _pollingTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (timer) => _performPollingTick(),
    );
    
    print('🔄 [SyncProvider] Polling started: ${intervalSeconds}s interval');
  }

  /// Parar polling
  Future<void> _stopPolling() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPollingActive = false;
    
    print('🔄 [SyncProvider] Polling stopped');
  }

  /// Tick de polling (llamado por el timer)
  Future<void> _performPollingTick() async {
    print('🔄 [SyncProvider] Polling tick - performing sync...');
    
    // Obtener token del storage
    final token = await storage_service.StorageService.getAccessToken();
    if (token != null) {
      await performIncrementalSync(token);
    } else {
      print('❌ [SyncProvider] No access token available for polling');
      await _stopPolling();
    }
  }

  /// Forzar sincronización manual
  Future<bool> forceSync(String token) async {
    print('🔄 [SyncProvider] Force sync requested');
    
    // Resetear ETag para forzar actualización completa
    final originalEtag = _currentEtag;
    _currentEtag = null;
    
    final success = await performIncrementalSync(token);
    
    // Si falla, restaurar ETag
    if (!success) {
      _currentEtag = originalEtag;
    }
    
    return success;
  }

  /// Forzar sincronización completa sin ETag (fresh data)
  Future<bool> forceFullSync(String token) async {
    print('🔄 [SyncProvider] Force FULL sync requested (no ETag)');
    
    _setLoading(true);
    _clearError();
    
    try {
      // Llamada directa a /api/v2/sync/ sin ETag
      final result = await SyncService.loadAllInitialPages(token: token);
      
      if (result.pages.isEmpty) {
        _setError('No se pudieron cargar datos');
        return false;
      }

      // Procesar todas las páginas como si fuera sync inicial
      await _processInitialPages(result.pages);
      
      // DEBUG: Verificar datos procesados ANTES de actualizar ETag
      print('🔍 [SyncProvider] DEBUG - Datos procesados:');
      print('  - hasNetworkData: $hasNetworkData');
      print('  - hasFulbitosData: $hasFulbitosData');
      if (hasNetworkData) {
        print('  - networkData.connections: ${_networkData!.connections.length}');
        print('  - networkData.pendingReceived: ${_networkData!.pendingReceived.length}');
      }
      
      // Solo actualizar ETag y timestamp si hay datos reales
      if (hasNetworkData || hasFulbitosData) {
        _currentEtag = result.etag;
        _lastSyncTimestamp = result.lastUpdate;
        
        // Guardar datos específicos
        if (hasNetworkData) {
          await _saveNetworkData();
          print('💾 [SyncProvider] Network data saved to storage');
        }
        if (hasFulbitosData) {
          await _saveFulbitosData();
          print('💾 [SyncProvider] Fulbitos data saved to storage');
        }
        
        // Guardar estado de sync
        await _saveSyncState();
        print('✅ [SyncProvider] ETag y timestamp actualizados');
      } else {
        print('⚠️ [SyncProvider] No hay datos nuevos, manteniendo ETag actual');
      }
      
      // CRÍTICO: Notificar a todos los listeners
      notifyListeners();
      
      // DEBUG: Esperar un momento para evitar conflictos con polling
      await Future.delayed(const Duration(milliseconds: 500));
      
      // DEBUG: Verificar que los datos siguen ahí después del delay
      print('🔍 [SyncProvider] DEBUG - Verificación post-delay:');
      print('  - hasNetworkData: $hasNetworkData');
      if (hasNetworkData) {
        print('  - networkData.connections: ${_networkData!.connections.length}');
      }
      
      print('✅ [SyncProvider] Force FULL sync completed successfully');
      return true;
      
    } catch (e) {
      print('❌ [SyncProvider] Force FULL sync failed: $e');
      _setError('Error en sincronización completa: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cargar estado de sincronización desde storage
  Future<void> loadSyncState() async {
    try {
      final etag = await storage_service.StorageService.getSyncEtag();
      final lastSync = await storage_service.StorageService.getLastSyncTimestamp();
      
      _currentEtag = etag;
      _lastSyncTimestamp = lastSync;
      
      // Cargar datos locales
      await _loadLocalData();
      
      // CRÍTICO: Notificar después de cargar datos desde storage
      notifyListeners();
    } catch (e) {
      print('❌ [SyncProvider] Error loading sync state: $e');
    }
  }

  /// Cargar datos locales (network y fulbitos) desde storage
  Future<void> _loadLocalData() async {
    try {
      // Cargar network data
      final networkDataJson = await storage_service.StorageService.getNetworkData();
      if (networkDataJson != null) {
        _networkData = SyncNetworkData.fromJson(networkDataJson);
        print('💾 Network data cargada: ${_networkData!.connections.length} conexiones, ${_networkData!.pendingReceived.length} invitaciones');
        print('💾 Network connections: ${_networkData!.connections.map((c) => c['username'] ?? 'Unknown').toList()}');
      } else {
        print('❌ No se encontraron datos de network en storage');
      }
      
      // Cargar fulbitos data
      final fulbitosDataJson = await storage_service.StorageService.getFulbitosData();
      if (fulbitosDataJson != null) {
        _fulbitosData = SyncFulbitosData.fromJson(fulbitosDataJson);
        print('💾 Fulbitos data cargada: ${_fulbitosData!.myFulbitos.length} propios, ${_fulbitosData!.memberFulbitos.length} como miembro');
      } else {
        print('❌ No se encontraron datos de fulbitos en storage');
      }
    } catch (e) {
      print('❌ [SyncProvider] Error loading local data: $e');
    }
  }

  /// Guardar estado de sincronización
  Future<void> _saveSyncState() async {
    try {
      await storage_service.StorageService.saveSyncEtag(_currentEtag);
      await storage_service.StorageService.saveLastSyncTimestamp(_lastSyncTimestamp);
      
      print('🔄 [SyncProvider] Sync state saved: ETag=$_currentEtag, LastSync=$_lastSyncTimestamp');
    } catch (e) {
      print('❌ [SyncProvider] Error saving sync state: $e');
    }
  }

  /// Limpiar estado de sincronización
  Future<void> clearSyncState() async {
    _currentEtag = null;
    _lastSyncTimestamp = null;
    _version = null;
    _networkData = null;
    _fulbitosData = null;
    _notificationsData = null;
    
    await _stopPolling();
    
    // Limpiar storage (sync state + data local)
    await storage_service.StorageService.clearSyncState();
    await storage_service.StorageService.clearLocalData();
    
    notifyListeners();
    print('🔄 [SyncProvider] Sync state and local data cleared');
  }

  /// Métodos privados para manejo de estado
  void _setLoading(bool loading, {bool isInitialLoad = false}) {
    _isLoading = loading;
    _isInitialLoad = isInitialLoad;
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

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}

