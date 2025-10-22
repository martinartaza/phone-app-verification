import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_response.dart';
import 'storage.dart' as storage_service;

class AuthService {
  static Future<Map<String, dynamic>> createUser(String phoneNumber, String timezone) async {
    try {
      print('📡 [AuthService] Enviando createUser request...');
      print('  - phoneNumber: $phoneNumber');
      print('  - timezone: $timezone');
      print('  - URL: ${ApiConfig.createUserUrl}');
      
      final uri = Uri.parse(ApiConfig.createUserUrl);
      final requestBody = jsonEncode({
        'phone_number': phoneNumber,
        'timezone': timezone,
      });
      
      print('📡 [AuthService] Request body: $requestBody');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );

      print('📡 [AuthService] Response received:');
      print('  - Status: ${response.statusCode}');
      print('  - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [AuthService] createUser successful');
        return {'success': true, 'message': 'Código enviado exitosamente'};
      } else {
        print('❌ [AuthService] createUser failed with status ${response.statusCode}');
        // Intentar parsear el mensaje de error del servidor
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Error del servidor';
          print('❌ [AuthService] Error message: $errorMessage');
          return {'success': false, 'message': errorMessage};
        } catch (e) {
          print('❌ [AuthService] Error parsing response: $e');
          return {'success': false, 'message': 'Error del servidor (${response.statusCode})'};
        }
      }
    } catch (e) {
      print('❌ [AuthService] Exception during createUser: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
  
  static Future<AuthResponse?> verifyUser(String phoneNumber, String code) async {
    try {
      final uri = Uri.parse(ApiConfig.verifyUserUrl);
      final requestBody = jsonEncode({
        'phone_number': phoneNumber,
        'verification_code': code,
      });
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        
        if (authResponse.isSuccess && authResponse.data != null) {
          print('💾 Guardando datos de autenticación...');
          
          // Guardar número de teléfono
          await storage_service.StorageService.savePhoneNumber(phoneNumber);
          print('  ✅ Teléfono guardado: $phoneNumber');
          
          // Guardar código de verificación
          await storage_service.StorageService.saveVerificationCode(code);
          print('  ✅ Código guardado: $code');
          
          // Guardar tokens (el API puede devolver nuevos tokens en cada verificación)
          await storage_service.StorageService.saveAuthTokens(
            accessToken: authResponse.data!.token,
            refreshToken: authResponse.data!.refreshToken,
          );
          print('  ✅ Tokens guardados');
          print('    - Access token: ${authResponse.data!.token.substring(0, 20)}...');
          print('    - Refresh token: ${authResponse.data!.refreshToken.substring(0, 20)}...');
          
          // Guardar datos del usuario
          await storage_service.StorageService.saveUserData(authResponse.data!.toJson());
          print('  ✅ Datos de usuario guardados');
          
          // Verificar que se guardaron correctamente
          final savedPhone = await storage_service.StorageService.getPhoneNumber();
          final savedCode = await storage_service.StorageService.getVerificationCode();
          final savedLoggedIn = await storage_service.StorageService.isLoggedIn();
          final savedRefresh = await storage_service.StorageService.getRefreshToken();
          
          print('🔍 Verificación post-guardado:');
          print('  - Teléfono: $savedPhone');
          print('  - Código: $savedCode');
          print('  - LoggedIn: $savedLoggedIn');
          print('  - Refresh token: ${savedRefresh != null ? "Presente" : "Ausente"}');
          
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
        print('❌ No hay refresh token disponible');
        return false;
      }

      print('🔄 Intentando refrescar access token...');
      final uri = Uri.parse(ApiConfig.refreshTokenUrl);
      final requestBody = jsonEncode({
        'refresh_token': refreshToken,
      });
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );
      
      print('📡 Respuesta del servidor: ${response.statusCode}');
      print('📡 Cuerpo de respuesta: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // El servidor devuelve la estructura: {status, message, data: {token, refresh_token}}
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          final data = responseData['data'];
          final newAccessToken = data['token'];
          final newRefreshToken = data['refresh_token'];
          
          if (newAccessToken != null) {
            // Actualizar ambos tokens (el servidor puede devolver nuevos)
            await storage_service.StorageService.saveAuthTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken ?? refreshToken, // Usar el nuevo o mantener el actual
            );
            
            // También actualizar los datos del usuario si vienen en la respuesta
            if (data['id'] != null) {
              final userData = UserData(
                id: data['id'],
                username: data['username'] ?? '',
                isActive: data['is_active'] ?? true,
                profile: UserProfile(
                  phoneNumber: data['profile']?['phone_number'] ?? '',
                  isVerified: data['profile']?['is_verified'] ?? true,
                ),
                token: newAccessToken,
                refreshToken: newRefreshToken ?? refreshToken,
              );
              
              await storage_service.StorageService.saveUserData(userData.toJson());
              print('✅ Datos de usuario actualizados');
            }
            
            print('✅ Access token refrescado exitosamente');
            return true;
          } else {
            print('❌ Respuesta sin token en data: $data');
            return false;
          }
        } else {
          print('❌ Respuesta con estructura incorrecta: $responseData');
          return false;
        }
      } else if (response.statusCode == 401) {
        print('❌ Refresh token inválido o expirado (401)');
        return false;
      } else {
        print('❌ Error del servidor al refrescar token: ${response.statusCode}');
        print('   Respuesta: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error de conexión al refrescar token: $e');
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