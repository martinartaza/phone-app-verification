import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class PhoneInputProvider extends ChangeNotifier {
  // Estado del formulario
  String _selectedCountryCode = '+54';
  String _phoneNumber = '';
  bool _isLoading = false;
  String? _errorMessage;

  // Lista de países disponibles
  final List<Map<String, String>> _countries = [
    {'name': 'Argentina', 'code': '+54', 'flag': '🇦🇷'},
    {'name': 'Peru', 'code': '+51', 'flag': '🇵🇪'},
    {'name': 'Chile', 'code': '+56', 'flag': '🇨🇱'},
    {'name': 'Colombia', 'code': '+57', 'flag': '🇨🇴'},
  ];

  // Getters
  String get selectedCountryCode => _selectedCountryCode;
  String get phoneNumber => _phoneNumber;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, String>> get countries => _countries;
  String get fullPhoneNumber => '$_selectedCountryCode$_phoneNumber';

  /// Constructor - cargar datos guardados
  PhoneInputProvider() {
    _loadSavedPhoneNumber();
  }

  /// Cargar número de teléfono guardado si existe
  Future<void> _loadSavedPhoneNumber() async {
    try {
      final savedPhoneNumber = await StorageService.getPhoneNumber();
      if (savedPhoneNumber != null) {
        // Extraer código de país y número
        for (var country in _countries) {
          if (savedPhoneNumber.startsWith(country['code']!)) {
            _selectedCountryCode = country['code']!;
            _phoneNumber = savedPhoneNumber.substring(country['code']!.length);
            notifyListeners();
            break;
          }
        }
        debugPrint('📱 Número de teléfono cargado: $savedPhoneNumber');
      }
    } catch (e) {
      debugPrint('❌ Error cargando número guardado: $e');
    }
  }

  /// Cambiar código de país seleccionado
  void setCountryCode(String countryCode) {
    _selectedCountryCode = countryCode;
    _clearError();
    notifyListeners();
  }

  /// Actualizar número de teléfono
  void setPhoneNumber(String phoneNumber) {
    print('📱 PhoneInputProvider.setPhoneNumber: "$phoneNumber"');
    _phoneNumber = phoneNumber;
    _clearError();
    notifyListeners();
    print('📱 Estado actualizado - fullPhoneNumber: $fullPhoneNumber');
  }

  /// Validar número de teléfono
  bool isPhoneNumberValid() {
    final isValid = _phoneNumber.isNotEmpty && _phoneNumber.length >= 7;
    print('🔍 Validando teléfono: "$_phoneNumber" (length: ${_phoneNumber.length}) -> válido: $isValid');
    return isValid;
  }

  /// Obtener mensaje de error de validación
  String? getValidationError() {
    if (_phoneNumber.isEmpty) {
      return 'Por favor ingresa tu número de teléfono';
    }
    if (_phoneNumber.length < 7) {
      return 'El número debe tener al menos 7 dígitos';
    }
    return null;
  }

  /// Establecer estado de carga
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Establecer mensaje de error
  void setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Limpiar error
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpiar formulario
  void clearForm() {
    _phoneNumber = '';
    _selectedCountryCode = '+54';
    _clearError();
    notifyListeners();
  }
}