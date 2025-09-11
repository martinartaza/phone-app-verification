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
}