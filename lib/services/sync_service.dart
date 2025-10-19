import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/sync_models.dart';

class SyncService {
  /// Carga inicial paginada - Primera sincronización
  static Future<SyncInitialResult?> loadInitialSync({
    required String token,
    required int nextPage,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.getSyncInitialUrl(nextPage));
      
      print('🔄 SYNC INITIAL - GET ${ApiConfig.syncInitialEndpoint}?next_page=$nextPage');
      print('🔄 Headers: Authorization: Bearer $token');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔄 Response Status: ${response.statusCode}');
      print('🔄 Response Headers: ${response.headers}');
      print('🔄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final syncResponse = SyncResponse.fromJson(responseData);
        
        // Extraer ETag y lastUpdate de los headers
        final etag = response.headers['etag'];
        final lastUpdate = response.headers['x-last-update'];
        
        print('🔄 ETag: $etag');
        print('🔄 Last Update: $lastUpdate');
        
        return SyncInitialResult(
          response: syncResponse,
          etag: etag,
          lastUpdate: lastUpdate,
        );
      } else {
        print('❌ SYNC INITIAL Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ SYNC INITIAL Error: $e');
      return null;
    }
  }

  /// Sincronización incremental - Actualizaciones con ETag y last_sync
  /// Devuelve cuerpo + headers relevantes (etag, x-last-update)
  static Future<SyncIncrementalResult?> syncIncremental({
    required String token,
    String? lastSync,
    String? etag,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.getSyncUrl(lastSync));
      
      print('🔄 SYNC INCREMENTAL - GET ${ApiConfig.syncEndpoint}');
      if (lastSync != null) print('🔄 Query: last_sync=$lastSync');
      if (etag != null) print('🔄 Header: If-None-Match=$etag');
      print('🔄 Headers: Authorization: Bearer $token');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      // Agregar ETag si está disponible
      if (etag != null) {
        headers['If-None-Match'] = etag;
      }

      final response = await http.get(
        url,
        headers: headers,
      );

      print('🔄 Response Status: ${response.statusCode}');
      print('🔄 Response Headers: ${response.headers}');
      print('🔄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Hay cambios - procesar respuesta completa
        final responseData = jsonDecode(response.body);
        final syncResponse = SyncResponse.fromJson(responseData);
        final newEtag = response.headers['etag'];
        final newLastUpdate = response.headers['x-last-update'];
        
        print('✅ SYNC: Changes detected, processing updates');
        return SyncIncrementalResult(
          response: syncResponse,
          etag: newEtag,
          lastUpdate: newLastUpdate,
        );
        
      } else if (response.statusCode == 304) {
        // No hay cambios - ETag coincide
        print('✅ SYNC: No changes detected (304 Not Modified)');
        
        // Extraer información de polling de los headers
        final nextPoll = response.headers['x-next-poll'];
        final needsPolling = response.headers['x-needs-polling'] == 'true';
        final newEtag = response.headers['etag'];
        final newLastUpdate = response.headers['x-last-update'];
        
        print('🔄 Next Poll: $nextPoll seconds');
        print('🔄 Needs Polling: $needsPolling');
        
        // Crear respuesta minimalista para indicar "sin cambios"
        return SyncIncrementalResult(
          response: SyncResponse(
          status: 'success',
          message: 'No changes detected',
          version: SyncVersion(global: '', network: '', fulbitos: ''),
          timestamp: DateTime.now().toIso8601String(),
          lastUpdate: newLastUpdate ?? '',
          polling: SyncPolling(
            needsPolling: needsPolling,
            nextPollSeconds: int.tryParse(nextPoll ?? '600') ?? 600,
            reason: 'no_changes',
            criticalEvents: [],
          ),
          ),
          etag: newEtag,
          lastUpdate: newLastUpdate,
        );
        
      } else {
        print('❌ SYNC INCREMENTAL Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ SYNC INCREMENTAL Error: $e');
      return null;
    }
  }

  /// Cargar todas las páginas de la sincronización inicial
  static Future<SyncInitialPagesResult> loadAllInitialPages({
    required String token,
  }) async {
    final List<SyncResponse> allPages = [];
    String? finalEtag;
    String? finalLastUpdate;
    int currentPage = 1;
    bool hasMorePages = true;

    print('🔄 SYNC: Starting initial load of all pages');

    while (hasMorePages) {
      final result = await loadInitialSync(
        token: token,
        nextPage: currentPage,
      );

      if (result != null) {
        allPages.add(result.response);
        
        // Guardar ETag y lastUpdate del último resultado
        finalEtag = result.etag;
        finalLastUpdate = result.lastUpdate;
        
        // Verificar si hay más páginas
        if (result.response.hasPagination && result.response.pagination!.hasNext) {
          currentPage++;
          print('🔄 SYNC: Loading page $currentPage...');
        } else {
          hasMorePages = false;
          print('🔄 SYNC: All pages loaded (total: ${allPages.length})');
        }
      } else {
        print('❌ SYNC: Failed to load page $currentPage, stopping');
        hasMorePages = false;
      }
    }

    return SyncInitialPagesResult(
      pages: allPages,
      etag: finalEtag,
      lastUpdate: finalLastUpdate,
    );
  }

  /// Obtener información de polling de una respuesta
  static SyncPollingInfo extractPollingInfo(SyncResponse response) {
    if (response.hasPolling) {
      return SyncPollingInfo(
        needsPolling: response.polling!.needsPolling,
        nextPollSeconds: response.polling!.nextPollSeconds,
        reason: response.polling!.reason,
        criticalEvents: response.polling!.criticalEvents,
      );
    }
    
    return SyncPollingInfo(
      needsPolling: false,
      nextPollSeconds: 600, // Default 10 minutes
      reason: 'default',
      criticalEvents: [],
    );
  }
}

/// Información de polling extraída de una respuesta de sincronización
class SyncPollingInfo {
  final bool needsPolling;
  final int nextPollSeconds;
  final String reason;
  final List<SyncCriticalEvent> criticalEvents;

  SyncPollingInfo({
    required this.needsPolling,
    required this.nextPollSeconds,
    required this.reason,
    required this.criticalEvents,
  });

  bool get isFulbitoActive => reason == 'fulbito_active';
  bool get isFulbitoOpening => reason == 'fulbito_opening';
  bool get isDefault => reason == 'default' || reason == 'no_changes';
  
  /// Determina si el polling debe ser más frecuente
  bool get requiresFrequentPolling => isFulbitoActive || isFulbitoOpening;
  
  /// Obtiene el intervalo de polling en segundos
  int get pollingIntervalSeconds {
    if (isFulbitoActive) return 30; // 30 segundos para fulbitos activos
    if (isFulbitoOpening) return 300; // 5 minutos para fulbitos próximos
    return nextPollSeconds; // Usar el valor del servidor o default
  }
}

/// Resultado de una sincronización inicial que incluye ETag y timestamp
class SyncInitialResult {
  final SyncResponse response;
  final String? etag;
  final String? lastUpdate;

  SyncInitialResult({
    required this.response,
    this.etag,
    this.lastUpdate,
  });
}

/// Resultado de cargar todas las páginas iniciales
class SyncInitialPagesResult {
  final List<SyncResponse> pages;
  final String? etag;
  final String? lastUpdate;

  SyncInitialPagesResult({
    required this.pages,
    this.etag,
    this.lastUpdate,
  });
}

/// Resultado de sincronización incremental
class SyncIncrementalResult {
  final SyncResponse response;
  final String? etag;
  final String? lastUpdate;

  SyncIncrementalResult({
    required this.response,
    this.etag,
    this.lastUpdate,
  });
}

