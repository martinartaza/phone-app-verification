import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_response.dart';
import 'storage.dart' as storage_service;

class AuthService {
  static Future<Map<String, dynamic>> createUser(String phoneNumber) async {
    try {
      final uri = Uri.parse(ApiConfig.createUserUrl);
      final requestBody = jsonEncode({
        'phone_number': phoneNumber,
      });
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Código enviado exitosamente'};
      } else {
        // Intentar parsear el mensaje de error del servidor
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Error del servidor';
          return {'success': false, 'message': errorMessage};
        } catch (e) {
          return {'success': false, 'message': 'Error del servidor (${response.statusCode})'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
  
  static Future<AuthResponse?> verifyUser(String phoneNumber, String code) async {
    try {
      final uri = Uri.parse(ApiConfig.verifyUserUrl);
      final requestBody = jsonEncode({
        'phone_number': phoneNumber,
        'code': code,
      });
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        
        if (authResponse.isSuccess && authResponse.data != null) {
          // Guardar número de teléfono
          await storage_service.StorageService.savePhoneNumber(phoneNumber);
          
          // Guardar código de verificación
          await storage_service.StorageService.saveVerificationCode(code);
          
          // Guardar tokens (el API puede devolver nuevos tokens en cada verificación)
          await storage_service.StorageService.saveAuthTokens(
            accessToken: authResponse.data!.token,
            refreshToken: authResponse.data!.refreshToken,
          );
          
          // Guardar datos del usuario
          await storage_service.StorageService.saveUserData(authResponse.data!.toJson());
          
          print('✅ Datos guardados exitosamente en el almacenamiento local');
          print('🔄 Refresh token válido por 10 días');
        }
        
        return authResponse;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Nuevo método para refrescar el token
  static Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await storage_service.StorageService.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final uri = Uri.parse(ApiConfig.refreshTokenUrl);
      final requestBody = jsonEncode({
        'refresh_token': refreshToken,
      });
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['access_token'] != null) {
          // Actualizar solo el access token
          await storage_service.StorageService.saveAuthTokens(
            accessToken: responseData['access_token'],
            refreshToken: refreshToken, // Mantener el mismo refresh token
          );
          
          return true;
        }
      }
      
      return false;
    } catch (e) {
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
      String? accessToken = await storage_service.StorageService.getAccessToken();
      
      // Verificar si el token ha expirado
      if (await storage_service.StorageService.isTokenExpired()) {
        final refreshed = await refreshAccessToken();
        if (!refreshed) {
          return null;
        }
        accessToken = await storage_service.StorageService.getAccessToken();
      }
      
      if (accessToken == null) {
        return null;
      }
      
      final requestHeaders = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        ...?headers,
      };
      
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
      
      return response;
    } catch (e) {
      return null;
    }
  }

  // Método para cerrar sesión
  static Future<void> logout() async {
    await storage_service.StorageService.clearAllData();
  }

  // Método para verificar si el usuario está autenticado
  static Future<bool> isAuthenticated() async {
    try {
      final isLoggedIn = await storage_service.StorageService.isLoggedIn();
      final hasValidToken = !(await storage_service.StorageService.isTokenExpired());
      final result = isLoggedIn && hasValidToken;
      
      return result;
    } catch (e) {
      return false;
    }
  }

  // Método para re-verificar automáticamente con datos guardados
  static Future<AuthResponse?> reVerifyWithStoredData() async {
    try {
      final phoneNumber = await storage_service.StorageService.getPhoneNumber();
      final verificationCode = await storage_service.StorageService.getVerificationCode();
      
      if (phoneNumber == null || verificationCode == null) {
        return null;
      }
      
      // Usar el método verifyUser existente
      return await verifyUser(phoneNumber, verificationCode);
    } catch (e) {
      return null;
    }
  }

  // Método simplificado - solo verifica si hay datos locales
  static Future<bool> hasLocalData() async {
    try {
      final isLoggedIn = await storage_service.StorageService.isLoggedIn();
      final phoneNumber = await storage_service.StorageService.getPhoneNumber();
      final verificationCode = await storage_service.StorageService.getVerificationCode();
      
      final hasData = isLoggedIn && phoneNumber != null && verificationCode != null;
      
      return hasData;
    } catch (e) {
      return false;
    }
  }
}