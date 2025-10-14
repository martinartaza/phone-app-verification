import 'package:flutter/foundation.dart';
import '../services/auth.dart' as auth_service;
import '../services/storage.dart' as storage_service;
import '../models/auth_response.dart';

class AuthProvider extends ChangeNotifier {
  // Estado de autenticación
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _phoneNumber;
  UserData? _userData;
  String? _errorMessage;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get phoneNumber => _phoneNumber;
  UserData? get userData => _userData;
  String? get errorMessage => _errorMessage;
  String? get token => _userData?.token;

  // Constructor
  AuthProvider() {
    _initializeAuth();
  }

  /// Inicializar estado de autenticación al crear el provider
  Future<void> _initializeAuth() async {
    _setLoading(true);
    
    try {
      print('🚀 Iniciando verificación de autenticación...');
      
      // Verificar si hay datos guardados (phone, code, token, refresh token)
      final phoneNumber = await storage_service.StorageService.getPhoneNumber();
      final verificationCode = await storage_service.StorageService.getVerificationCode();
      final isLoggedIn = await storage_service.StorageService.isLoggedIn();
      final refreshToken = await storage_service.StorageService.getRefreshToken();
      final accessToken = await storage_service.StorageService.getAccessToken();
      
      print('🔍 Verificando datos locales:');
      print('  - phoneNumber: $phoneNumber');
      print('  - verificationCode: $verificationCode');
      print('  - isLoggedIn: $isLoggedIn');
      print('  - refreshToken: ${refreshToken != null ? "Presente (${refreshToken.length} chars)" : "Ausente"}');
      print('  - accessToken: ${accessToken != null ? "Presente (${accessToken.length} chars)" : "Ausente"}');
      
      // Si NO tiene datos guardados -> Va a phone_input
      if (phoneNumber == null || verificationCode == null || !isLoggedIn || refreshToken == null) {
        print('❌ Datos locales incompletos o ausentes -> Ir a phone_input');
        _isAuthenticated = false;
        _isInitialized = true;
        return;
      }
      
      // Si YA tiene datos guardados -> Intentar refresh token
      print('📡 Datos locales encontrados, intentando refresh token...');
      
      // Paso 1: Intentar refresh-token
      final refreshSuccess = await auth_service.AuthService.refreshAccessToken();
      
      if (refreshSuccess) {
        // Caso 1: refresh-token responde success -> va al home
        print('✅ Refresh token exitoso -> Ir al home');
        _isAuthenticated = true;
        _phoneNumber = phoneNumber;
        _userData = await _getUserDataFromStorage();
      } else {
        // Caso 2: refresh-token responde error -> intentar verify-user con datos guardados
        print('❌ Refresh token falló -> Intentando verify-user con datos guardados');
        
        final reVerifyResponse = await auth_service.AuthService.reVerifyWithStoredData();
        
        if (reVerifyResponse != null && reVerifyResponse.isSuccess) {
          // verify-user responde ok -> va al home
          print('✅ Re-verificación exitosa -> Ir al home');
          _isAuthenticated = true;
          _phoneNumber = phoneNumber;
          _userData = reVerifyResponse.data;
        } else {
          // verify-user responde error -> va a phone_input
          print('❌ Re-verificación falló -> Limpiar datos y ir a phone_input');
          await _clearLocalDataAndSetUnauthenticated();
        }
      }
      
      _isInitialized = true;
      print('🏁 Inicialización completada. Autenticado: $_isAuthenticated');
    } catch (e) {
      print('❌ Error inicializando autenticación: $e');
      await _clearLocalDataAndSetUnauthenticated();
      _isInitialized = true;
    } finally {
      _setLoading(false);
    }
  }

  /// Limpiar datos locales y marcar como no autenticado
  Future<void> _clearLocalDataAndSetUnauthenticated() async {
    await storage_service.StorageService.clearAllData();
    _isAuthenticated = false;
    _phoneNumber = null;
    _userData = null;
    _clearError();
  }

  /// Enviar código de verificación
  Future<bool> sendVerificationCode(String phoneNumber, String timezone) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await auth_service.AuthService.createUser(phoneNumber, timezone);
      if (result['success']) {
        _phoneNumber = phoneNumber;
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] ?? 'Error al enviar el código');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verificar código y autenticar usuario
  Future<bool> verifyCode(String phoneNumber, String code) async {
    _setLoading(true);
    _clearError();
    
    try {
      final authResponse = await auth_service.AuthService.verifyUser(phoneNumber, code);
      
      if (authResponse != null && authResponse.isSuccess) {
        _isAuthenticated = true;
        _phoneNumber = phoneNumber;
        _userData = authResponse.data;
        notifyListeners();
        return true;
      } else {
        _setError(authResponse?.message ?? 'Código incorrecto');
        return false;
      }
    } catch (e) {
      _setError('Error de verificación: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await auth_service.AuthService.logout();
      _isAuthenticated = false;
      _phoneNumber = null;
      _userData = null;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Error al cerrar sesión: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refrescar datos del usuario
  Future<void> refreshUserData() async {
    if (!_isAuthenticated) return;
    
    try {
      _userData = await _getUserDataFromStorage();
      notifyListeners();
    } catch (e) {
      _setError('Error refrescando datos: $e');
    }
  }

  /// Obtener datos del usuario desde storage
  Future<UserData?> _getUserDataFromStorage() async {
    final userData = await storage_service.StorageService.getUserData();
    if (userData != null) {
      return UserData.fromJson(userData);
    }
    return null;
  }

  /// Obtener todos los datos almacenados (para debug)
  Future<Map<String, dynamic>> getStoredData() async {
    return await storage_service.StorageService.getAllStoredData();
  }

  /// Método de debug para imprimir todos los datos guardados
  Future<void> debugPrintStoredData() async {
    final data = await getStoredData();
    print('🐛 DEBUG - Datos guardados localmente:');
    data.forEach((key, value) {
      if (key.contains('token') && value != null) {
        print('  $key: ${value.toString().substring(0, 20)}...');
      } else {
        print('  $key: $value');
      }
    });
  }

  /// Método simple para verificar si hay datos básicos (sin validaciones complejas)
  Future<bool> hasBasicStoredData() async {
    final phoneNumber = await storage_service.StorageService.getPhoneNumber();
    final verificationCode = await storage_service.StorageService.getVerificationCode();
    final isLoggedIn = await storage_service.StorageService.isLoggedIn();
    
    final hasData = phoneNumber != null && verificationCode != null && isLoggedIn;
    print('🔍 Datos básicos presentes: $hasData');
    return hasData;
  }

  /// Verificar con el servidor usando datos guardados
  Future<bool> verifyWithServer() async {
    if (!_isAuthenticated) return false;
    
    _setLoading(true);
    
    try {
      // Primero intentar refrescar el token
      final refreshSuccess = await auth_service.AuthService.refreshAccessToken();
      
      if (refreshSuccess) {
        // Si el refresh fue exitoso, actualizar datos del usuario
        _userData = await _getUserDataFromStorage();
        notifyListeners();
        return true;
      } else {
        // Si el refresh falló, intentar re-verificar con datos guardados
        final reVerifyResponse = await auth_service.AuthService.reVerifyWithStoredData();
        
        if (reVerifyResponse != null && reVerifyResponse.isSuccess) {
          // El servidor confirmó que los datos son válidos
          _userData = reVerifyResponse.data;
          notifyListeners();
          return true;
        } else {
          // El servidor rechazó los datos (pueden haber expirado)
          await logout();
          return false;
        }
      }
    } catch (e) {
      _setError('Error verificando con servidor: $e');
      // En caso de error de red, mantener sesión local
      return true;
    } finally {
      _setLoading(false);
    }
  }

  /// Verificar y renovar tokens si es necesario (método manual)
  Future<bool> checkAndRenewTokens() async {
    // Este método ahora es solo para renovación manual
    return await verifyWithServer();
  }

  // Métodos privados para manejo de estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}