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
      
      final response = await SyncService.syncIncremental(
        token: token,
        lastSync: _lastSyncTimestamp,
        etag: _currentEtag,
      );
      
      if (response != null) {
        await _processSyncResponse(response);
        await _saveSyncState();
        
        // Actualizar polling si es necesario
        final pollingInfo = SyncService.extractPollingInfo(response);
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
    // Actualizar versión y timestamps
    _version = response.version;
    _lastSyncTimestamp = response.lastUpdate;
    
    // Procesar datos de red
    if (response.hasData && response.data!.network != null) {
      _networkData = response.data!.network!;
      print('🔄 [SyncProvider] Network data updated: ${_networkData!.totalConnections} connections');
    }
    
    // Procesar datos de fulbitos
    if (response.hasData && response.data!.fulbitos != null) {
      _fulbitosData = response.data!.fulbitos!;
      print('🔄 [SyncProvider] Fulbitos data updated: ${_fulbitosData!.totalMyFulbitos} my fulbitos');
    }
    
    // Procesar notificaciones
    if (response.hasData && response.data!.notifications != null) {
      _notificationsData = response.data!.notifications!;
      print('🔄 [SyncProvider] Notifications updated: ${_notificationsData!.total} total');
    }
    
    notifyListeners();
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

  /// Cargar estado de sincronización desde storage
  Future<void> loadSyncState() async {
    try {
      final etag = await storage_service.StorageService.getSyncEtag();
      final lastSync = await storage_service.StorageService.getLastSyncTimestamp();
      
      _currentEtag = etag;
      _lastSyncTimestamp = lastSync;
      
      print('🔄 [SyncProvider] Sync state loaded: ETag=$etag, LastSync=$lastSync');
    } catch (e) {
      print('❌ [SyncProvider] Error loading sync state: $e');
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
    
    // Limpiar storage
    await storage_service.StorageService.clearSyncState();
    
    notifyListeners();
    print('🔄 [SyncProvider] Sync state cleared');
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

