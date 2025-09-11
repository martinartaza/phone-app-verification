import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_response.dart';
import 'storage_service.dart';

class AuthService {
  static Future<bool> createUser(String phoneNumber) async {
    try {
      final uri = Uri.parse(ApiConfig.createUserUrl);
      final requestBody = jsonEncode({
        'phone_number': phoneNumber,
      });
      
      print('\n=== CREATE USER API CALL ===');
      print('URI: $uri');
      print('Method: POST');
      print('Headers: Content-Type: application/json, Accept: application/json');
      print('Request Body: $requestBody');
      print('============================\n');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );

      print('=== CREATE USER RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Response Headers: ${response.headers}');
      print('============================\n');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('=== CREATE USER ERROR ===');
      print('Error: $e');
      print('========================\n');
      return false;
    }
  }
  
  static Future<AuthResponse?> verifyUser(String phoneNumber, String code) async {
    try {
      final uri = Uri.parse(ApiConfig.verifyUserUrl);
      final requestBody = jsonEncode({
        'phone_number': phoneNumber,
        'code': code,
      });
      
      print('\n=== VERIFY USER API CALL ===');
      print('URI: $uri');
      print('Method: POST');
      print('Headers: Content-Type: application/json');
      print('Request Body: $requestBody');
      print('============================\n');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );
      
      print('=== VERIFY USER RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Response Headers: ${response.headers}');
      print('============================\n');
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        
        if (authResponse.isSuccess && authResponse.data != null) {
          // Guardar número de teléfono
          await StorageService.savePhoneNumber(phoneNumber);
          
          // Guardar código de verificación
          await StorageService.saveVerificationCode(code);
          
          // Guardar tokens (el API puede devolver nuevos tokens en cada verificación)
          await StorageService.saveAuthTokens(
            accessToken: authResponse.data!.token,
            refreshToken: authResponse.data!.refreshToken,
          );
          
          // Guardar datos del usuario
          await StorageService.saveUserData(authResponse.data!.toJson());
          
          print('✅ Datos guardados exitosamente en el almacenamiento local');
          print('🔄 Refresh token válido por 10 días');
        }
        
        return authResponse;
      }
      
      return null;
    } catch (e) {
      print('=== VERIFY USER ERROR ===');
      print('Error: $e');
      print('========================\n');
      return null;
    }
  }

  // Nuevo método para refrescar el token
  static Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) {
        print('❌ No hay refresh token disponible');
        return false;
      }

      final uri = Uri.parse(ApiConfig.refreshTokenUrl);
      final requestBody = jsonEncode({
        'refresh_token': refreshToken,
      });
      
      print('\n=== REFRESH TOKEN API CALL ===');
      print('URI: $uri');
      print('Method: POST');
      print('Headers: Content-Type: application/json');
      print('Request Body: $requestBody');
      print('===============================\n');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );
      
      print('=== REFRESH TOKEN RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Response Headers: ${response.headers}');
      print('===============================\n');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['access_token'] != null) {
          // Actualizar solo el access token
          await StorageService.saveAuthTokens(
            accessToken: responseData['access_token'],
            refreshToken: refreshToken, // Mantener el mismo refresh token
          );
          
          print('✅ Access token actualizado exitosamente');
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('=== REFRESH TOKEN ERROR ===');
      print('Error: $e');
      print('===========================\n');
      return false;
    }
  }

  // Método para hacer peticiones autenticadas
  static Future<http.Response?> authenticatedRequest({
    required String url,
    required String method,
    Map<String, String>? headers,
    String? body,
  }) async {
    try {
      String? accessToken = await StorageService.getAccessToken();
      
      // Verificar si el token ha expirado
      if (await StorageService.isTokenExpired()) {
        print('🔄 Token expirado, intentando refrescar...');
        final refreshed = await refreshAccessToken();
        if (!refreshed) {
          print('❌ No se pudo refrescar el token');
          return null;
        }
        accessToken = await StorageService.getAccessToken();
      }
      
      if (accessToken == null) {
        print('❌ No hay access token disponible');
        return null;
      }
      
      final requestHeaders = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        ...?headers,
      };
      
      print('\n=== AUTHENTICATED REQUEST ===');
      print('URL: $url');
      print('Method: $method');
      print('Headers: $requestHeaders');
      if (body != null) print('Body: $body');
      print('=============================\n');
      
      http.Response response;
      final uri = Uri.parse(url);
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(uri, headers: requestHeaders, body: body);
          break;
        case 'PUT':
          response = await http.put(uri, headers: requestHeaders, body: body);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: requestHeaders);
          break;
        default:
          throw Exception('Método HTTP no soportado: $method');
      }
      
      print('=== AUTHENTICATED RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('===============================\n');
      
      return response;
    } catch (e) {
      print('=== AUTHENTICATED REQUEST ERROR ===');
      print('Error: $e');
      print('===================================\n');
      return null;
    }
  }

  // Método para cerrar sesión
  static Future<void> logout() async {
    await StorageService.clearAllData();
    print('👋 Sesión cerrada, datos eliminados');
  }

  // Método para verificar si el usuario está autenticado
  static Future<bool> isAuthenticated() async {
    try {
      final isLoggedIn = await StorageService.isLoggedIn();
      final hasValidToken = !(await StorageService.isTokenExpired());
      final result = isLoggedIn && hasValidToken;
      
      print('🔍 Verificando autenticación:');
      print('  - isLoggedIn: $isLoggedIn');
      print('  - hasValidToken: $hasValidToken');
      print('  - resultado final: $result');
      
      return result;
    } catch (e) {
      print('❌ Error verificando autenticación: $e');
      return false;
    }
  }
}