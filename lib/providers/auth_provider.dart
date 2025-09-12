import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
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

  // Constructor
  AuthProvider() {
    _initializeAuth();
  }

  /// Inicializar estado de autenticación al crear el provider
  Future<void> _initializeAuth() async {
    _setLoading(true);
    
    try {
      print('🔄 Inicializando AuthProvider...');
      
      // Verificar si hay datos guardados (teléfono y código)
      final phoneNumber = await StorageService.getPhoneNumber();
      final verificationCode = await StorageService.getVerificationCode();
      final isLoggedIn = await StorageService.isLoggedIn();
      
      print('🔍 Verificando datos locales:');
      print('  - phoneNumber: $phoneNumber');
      print('  - verificationCode: $verificationCode');
      print('  - isLoggedIn: $isLoggedIn');
      
      // Si hay datos guardados, considerar como autenticado para ir al Home
      if (phoneNumber != null && verificationCode != null && isLoggedIn) {
        _isAuthenticated = true;
        _phoneNumber = phoneNumber;
        _userData = await _getUserDataFromStorage();
        print('✅ Datos locales encontrados, ir al Home para verificar con servidor');
      } else {
        _isAuthenticated = false;
        print('❌ No hay datos locales, ir al login');
      }
      
      _isInitialized = true;
      print('✅ AuthProvider inicializado correctamente');
    } catch (e) {
      print('❌ Error inicializando AuthProvider: $e');
      _setError('Error inicializando autenticación: $e');
      _isInitialized = true; // Marcar como inicializado aunque haya error
    } finally {
      _setLoading(false);
    }
  }

  /// Enviar código de verificación
  Future<bool> sendVerificationCode(String phoneNumber) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await AuthService.createUser(phoneNumber);
      if (success) {
        _phoneNumber = phoneNumber;
        notifyListeners();
        return true;
      } else {
        _setError('Error al enviar el código');
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
      final authResponse = await AuthService.verifyUser(phoneNumber, code);
      
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
      await AuthService.logout();
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
    final userData = await StorageService.getUserData();
    if (userData != null) {
      return UserData.fromJson(userData);
    }
    return null;
  }

  /// Obtener todos los datos almacenados (para debug)
  Future<Map<String, dynamic>> getStoredData() async {
    return await StorageService.getAllStoredData();
  }

  /// Verificar con el servidor usando datos guardados
  Future<bool> verifyWithServer() async {
    if (!_isAuthenticated) return false;
    
    _setLoading(true);
    
    try {
      print('🔄 Verificando con servidor usando datos guardados...');
      
      final reVerifyResponse = await AuthService.reVerifyWithStoredData();
      
      if (reVerifyResponse != null && reVerifyResponse.isSuccess) {
        // El servidor confirmó que los datos son válidos
        _userData = reVerifyResponse.data;
        print('✅ Servidor confirmó validez, tokens actualizados');
        notifyListeners();
        return true;
      } else {
        // El servidor rechazó los datos (pueden haber expirado)
        print('❌ Servidor rechazó verificación, limpiando datos');
        await logout();
        return false;
      }
    } catch (e) {
      print('❌ Error verificando con servidor: $e');
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