import 'package:http/http.dart' as http;
import 'dart:convert';

/// Cliente HTTP centralizado que maneja sync automático después de mutaciones
/// 
/// Este cliente intercepta todas las llamadas POST/PUT/DELETE y automáticamente
/// dispara un sync incremental después de operaciones exitosas.
/// 
/// Uso:
/// ```dart
/// final client = ApiClient(token: token, syncProvider: syncProvider);
/// final response = await client.post('/api/v2/network/invite/', body: {...});
/// // Sync se dispara automáticamente si statusCode == 200/201
/// ```
class ApiClient {
  final String token;
  final Function(String token)? onSyncRequired;
  
  ApiClient({
    required this.token,
    this.onSyncRequired,
  });

  /// Headers comunes para todas las requests
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  /// Headers para multipart/form-data
  Map<String, String> get _headersMultipart => {
    'Authorization': 'Bearer $token',
  };

  /// GET request
  Future<http.Response> get(String url) async {
    print('📥 API GET - $url');
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    print('📥 Response Status: ${response.statusCode}');
    return response;
  }

  /// POST request con sync automático
  Future<http.Response> post(
    String url, {
    Map<String, dynamic>? body,
    bool triggerSync = true,
  }) async {
    print('📤 API POST - $url');
    print('📤 Body: ${jsonEncode(body)}');
    
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(body),
    );
    
    print('📤 Response Status: ${response.statusCode}');
    print('📤 Response Body: ${response.body}');
    
    // Sync automático después de mutación exitosa
    if (triggerSync && _shouldTriggerSync(response.statusCode)) {
      await _triggerSync();
    }
    
    return response;
  }

  /// PUT request con sync automático
  Future<http.Response> put(
    String url, {
    Map<String, dynamic>? body,
    bool triggerSync = true,
  }) async {
    print('📤 API PUT - $url');
    print('📤 Body: ${jsonEncode(body)}');
    
    final response = await http.put(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(body),
    );
    
    print('📤 Response Status: ${response.statusCode}');
    print('📤 Response Body: ${response.body}');
    
    // Sync automático después de mutación exitosa
    if (triggerSync && _shouldTriggerSync(response.statusCode)) {
      await _triggerSync();
    }
    
    return response;
  }

  /// DELETE request con sync automático
  Future<http.Response> delete(
    String url, {
    bool triggerSync = true,
  }) async {
    print('📤 API DELETE - $url');
    
    final response = await http.delete(
      Uri.parse(url),
      headers: _headers,
    );
    
    print('📤 Response Status: ${response.statusCode}');
    
    // Sync automático después de mutación exitosa
    if (triggerSync && _shouldTriggerSync(response.statusCode)) {
      await _triggerSync();
    }
    
    return response;
  }

  /// POST multipart/form-data (para uploads de archivos)
  Future<http.StreamedResponse> postMultipart(
    String url, {
    required Map<String, String> fields,
    Map<String, String>? files, // filepath -> fieldName
    bool triggerSync = true,
  }) async {
    print('📤 API POST MULTIPART - $url');
    
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(_headersMultipart);
    request.fields.addAll(fields);
    
    // Agregar archivos si existen
    if (files != null) {
      for (var entry in files.entries) {
        final filepath = entry.key;
        final fieldName = entry.value;
        request.files.add(await http.MultipartFile.fromPath(fieldName, filepath));
      }
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    print('📤 Response Status: ${response.statusCode}');
    
    // Sync automático después de mutación exitosa
    if (triggerSync && _shouldTriggerSync(response.statusCode)) {
      await _triggerSync();
    }
    
    return streamedResponse;
  }

  /// PUT multipart/form-data (para updates con archivos)
  Future<http.StreamedResponse> putMultipart(
    String url, {
    required Map<String, String> fields,
    Map<String, String>? files, // filepath -> fieldName
    bool triggerSync = true,
  }) async {
    print('📤 API PUT MULTIPART - $url');
    
    final request = http.MultipartRequest('PUT', Uri.parse(url));
    request.headers.addAll(_headersMultipart);
    request.fields.addAll(fields);
    
    // Agregar archivos si existen
    if (files != null) {
      for (var entry in files.entries) {
        final filepath = entry.key;
        final fieldName = entry.value;
        request.files.add(await http.MultipartFile.fromPath(fieldName, filepath));
      }
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    print('📤 Response Status: ${response.statusCode}');
    
    // Sync automático después de mutación exitosa
    if (triggerSync && _shouldTriggerSync(response.statusCode)) {
      await _triggerSync();
    }
    
    return streamedResponse;
  }

  /// Determina si debe disparar sync basado en status code
  bool _shouldTriggerSync(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  /// Dispara sync incremental
  Future<void> _triggerSync() async {
    if (onSyncRequired != null) {
      print('🔄 [ApiClient] Triggering automatic sync after mutation...');
      try {
        await onSyncRequired!(token);
        print('✅ [ApiClient] Automatic sync completed');
      } catch (e) {
        print('❌ [ApiClient] Error during automatic sync: $e');
        // No lanzamos el error para no bloquear la operación principal
      }
    } else {
      print('⚠️ [ApiClient] No sync callback configured');
    }
  }
}


