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
      _isAuthenticated = await AuthService.isAuthenticated();
      print('🔍 isAuthenticated: $_isAuthenticated');
      
      if (_isAuthenticated) {
        _phoneNumber = await StorageService.getPhoneNumber();
        _userData = await _getUserDataFromStorage();
        print('📱 Datos cargados - Teléfono: $_phoneNumber, Usuario: ${_userData?.username}');
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