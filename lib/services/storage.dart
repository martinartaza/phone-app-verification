import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _phoneNumberKey = 'phone_number';
  static const String _verificationCodeKey = 'verification_code';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  // Guardar número de teléfono
  static Future<void> savePhoneNumber(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneNumberKey, phoneNumber);
    print('📱 Número de teléfono guardado: $phoneNumber');
  }

  // Obtener número de teléfono guardado
  static Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString(_phoneNumberKey);
    print('📱 Número de teléfono recuperado: $phoneNumber');
    return phoneNumber;
  }

  // Guardar código de verificación
  static Future<void> saveVerificationCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_verificationCodeKey, code);
    print('🔢 Código de verificación guardado: $code');
  }

  // Obtener código de verificación guardado
  static Future<String?> getVerificationCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_verificationCodeKey);
    print('🔢 Código de verificación recuperado: $code');
    return code;
  }

  // Guardar tokens de autenticación
  static Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setBool(_isLoggedInKey, true);
    
    print('🔐 Tokens guardados:');
    print('  Access Token: ${accessToken.substring(0, 20)}...');
    print('  Refresh Token: ${refreshToken.substring(0, 20)}...');
  }

  // Obtener access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // Obtener refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Guardar datos completos del usuario
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
    print('👤 Datos de usuario guardados: ${userData['username']}');
  }

  // Obtener datos del usuario
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  // Verificar si el usuario está logueado
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Limpiar todos los datos (logout)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_verificationCodeKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
    await prefs.setBool(_isLoggedInKey, false);
    print('🗑️ Todos los datos han sido eliminados');
  }

  // Obtener todos los datos guardados (para debug)
  static Future<Map<String, dynamic>> getAllStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'phone_number': prefs.getString(_phoneNumberKey),
      'verification_code': prefs.getString(_verificationCodeKey),
      'access_token': prefs.getString(_accessTokenKey),
      'refresh_token': prefs.getString(_refreshTokenKey),
      'user_data': prefs.getString(_userDataKey),
      'is_logged_in': prefs.getBool(_isLoggedInKey),
    };
  }

  // Verificar si el token ha expirado (básico)
  static Future<bool> isTokenExpired() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return true;
    
    try {
      // Decodificar el JWT para verificar la expiración
      final parts = accessToken.split('.');
      if (parts.length != 3) return true;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(decoded);
      
      final exp = payloadMap['exp'];
      if (exp == null) return true;
      
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      
      final isExpired = now.isAfter(expirationDate);
      print('🕐 Token expira: $expirationDate, Ahora: $now, Expirado: $isExpired');
      
      return isExpired;
    } catch (e) {
      print('❌ Error verificando expiración del token: $e');
      return true;
    }
  }

  // Verificar si el token necesita renovación (próximo a vencer)
  static Future<bool> shouldRenewToken() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return false;
    
    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) return false;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(decoded);
      
      final exp = payloadMap['exp'];
      if (exp == null) return false;
      
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      
      // Renovar si queda menos de 1 día para expirar
      final hoursUntilExpiry = expirationDate.difference(now).inHours;
      final shouldRenew = hoursUntilExpiry < 24;
      
      print('⏰ Token expira en $hoursUntilExpiry horas, Renovar: $shouldRenew');
      
      return shouldRenew;
    } catch (e) {
      print('❌ Error verificando renovación del token: $e');
      return false;
    }
  }

  // Verificar si el refresh token ha expirado (10 días)
  static Future<bool> isRefreshTokenExpired() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      print('🔄 No hay refresh token, considerando expirado');
      return true;
    }
    
    try {
      print('🔄 Verificando expiración del refresh token...');
      final parts = refreshToken.split('.');
      if (parts.length != 3) {
        print('❌ Refresh token no tiene formato JWT válido');
        return true;
      }
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(decoded);
      
      final exp = payloadMap['exp'];
      if (exp == null) {
        print('❌ Refresh token no tiene campo exp');
        return true;
      }
      
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      
      final isExpired = now.isAfter(expirationDate);
      print('🔄 Refresh token expira: $expirationDate, Ahora: $now, Expirado: $isExpired');
      
      return isExpired;
    } catch (e) {
      print('❌ Error verificando expiración del refresh token: $e');
      // En caso de error, asumir que no está expirado para intentar usarlo
      return false;
    }
  }

  // ========== MÉTODOS DE SINCRONIZACIÓN ==========

  /// Guardar ETag de sincronización
  static Future<void> saveSyncEtag(String? etag) async {
    final prefs = await SharedPreferences.getInstance();
    if (etag != null) {
      await prefs.setString('sync_etag', etag);
      print('💾 Sync ETag guardado: $etag');
    } else {
      await prefs.remove('sync_etag');
      print('💾 Sync ETag eliminado');
    }
  }

  /// Obtener ETag de sincronización
  static Future<String?> getSyncEtag() async {
    final prefs = await SharedPreferences.getInstance();
    final etag = prefs.getString('sync_etag');
    print('💾 Sync ETag cargado: $etag');
    return etag;
  }

  /// Guardar timestamp de última sincronización
  static Future<void> saveLastSyncTimestamp(String? timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    if (timestamp != null) {
      await prefs.setString('last_sync_timestamp', timestamp);
      print('💾 Last sync timestamp guardado: $timestamp');
    } else {
      await prefs.remove('last_sync_timestamp');
      print('💾 Last sync timestamp eliminado');
    }
  }

  /// Obtener timestamp de última sincronización
  static Future<String?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString('last_sync_timestamp');
    print('💾 Last sync timestamp cargado: $timestamp');
    return timestamp;
  }

  /// Limpiar estado de sincronización
  static Future<void> clearSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sync_etag');
    await prefs.remove('last_sync_timestamp');
    print('💾 Estado de sincronización limpiado');
  }
}