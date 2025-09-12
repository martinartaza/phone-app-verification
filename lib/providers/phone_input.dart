import 'package:flutter/foundation.dart';
import '../services/storage.dart' as storage_service;

class PhoneInputProvider extends ChangeNotifier {
  // Estado del formulario
  String _selectedCountryCode = '+54';
  String _selectedProvinceCode = '';
  String _phoneNumber = '';
  bool _isLoading = false;
  String? _errorMessage;

  // Lista de países disponibles (preparado para expansión)
  final List<Map<String, String>> _countries = [
    {'name': 'Argentina', 'code': '+54', 'flag': '🇦🇷'},
    {'name': 'Peru', 'code': '+51', 'flag': '🇵🇪'},
    {'name': 'Chile', 'code': '+56', 'flag': '🇨🇱'},
    {'name': 'Colombia', 'code': '+57', 'flag': '🇨🇴'},
  ];
  
  // Lista de provincias argentinas con códigos de área
  final List<Map<String, String>> _provinces = [
    {'name': 'Seleccionar provincia', 'code': ''},
    {'name': 'Ciudad Autónoma de Buenos Aires', 'code': '011'},
    {'name': 'La Plata (Buenos Aires)', 'code': '221'},
    {'name': 'Catamarca', 'code': '383'},
    {'name': 'Chaco', 'code': '362'},
    {'name': 'Chubut', 'code': '280'},
    {'name': 'Córdoba', 'code': '351'},
    {'name': 'Corrientes', 'code': '379'},
    {'name': 'Entre Ríos', 'code': '343'},
    {'name': 'Formosa', 'code': '370'},
    {'name': 'Jujuy', 'code': '388'},
    {'name': 'La Pampa', 'code': '2954'},
    {'name': 'La Rioja', 'code': '380'},
    {'name': 'Mendoza', 'code': '261'},
    {'name': 'Misiones', 'code': '376'},
    {'name': 'Neuquén', 'code': '299'},
    {'name': 'Río Negro', 'code': '2920'},
    {'name': 'Salta', 'code': '387'},
    {'name': 'San Juan', 'code': '264'},
    {'name': 'San Luis', 'code': '266'},
    {'name': 'Santa Cruz', 'code': '2966'},
    {'name': 'Santa Fe', 'code': '342'},
    {'name': 'Santiago del Estero', 'code': '385'},
    {'name': 'Tierra del Fuego', 'code': '2901'},
    {'name': 'Tucumán', 'code': '381'},
  ];

  // Getters
  String get selectedCountryCode => _selectedCountryCode;
  String get selectedProvinceCode => _selectedProvinceCode;
  String get phoneNumber => _phoneNumber;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, String>> get countries => _countries;
  Map<String, String> get selectedCountry => _countries.firstWhere(
    (country) => country['code'] == _selectedCountryCode,
    orElse: () => _countries.first,
  );
  List<Map<String, String>> get provinces => _provinces;
  String get fullPhoneNumber => '$_selectedCountryCode$_phoneNumber';

  /// Constructor - cargar datos guardados
  PhoneInputProvider() {
    _loadSavedPhoneNumber();
  }

  /// Cargar número de teléfono guardado si existe
  Future<void> _loadSavedPhoneNumber() async {
    try {
      final savedPhoneNumber = await storage_service.StorageService.getPhoneNumber();
      if (savedPhoneNumber != null) {
        // Detectar país basado en el código
        for (var country in _countries) {
          if (savedPhoneNumber.startsWith(country['code']!)) {
            _selectedCountryCode = country['code']!;
            _phoneNumber = savedPhoneNumber.substring(country['code']!.length);
            
            // Si es Argentina, intentar detectar la provincia
            if (_selectedCountryCode == '+54' && _phoneNumber.startsWith('9')) {
              final phoneWithoutNine = _phoneNumber.substring(1);
              for (var province in _provinces) {
                if (province['code']!.isNotEmpty && phoneWithoutNine.startsWith(province['code']!)) {
                  _selectedProvinceCode = province['code']!;
                  break;
                }
              }
            }
            break;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      // Error silencioso
    }
  }

  /// Cambiar código de país seleccionado
  void setCountryCode(String countryCode) {
    _selectedCountryCode = countryCode;
    
    // Limpiar provincia y número al cambiar país
    _selectedProvinceCode = '';
    _phoneNumber = '';
    
    _clearError();
    notifyListeners();
  }

  /// Seleccionar provincia y auto-completar código de área (solo para Argentina)
  void setProvince(String provinceCode) {
    _selectedProvinceCode = provinceCode;
    
    if (_selectedCountryCode == '+54' && provinceCode.isNotEmpty) {
      // Auto-completar con 9 + código de área para Argentina
      _phoneNumber = '9$provinceCode';
    } else if (provinceCode.isEmpty) {
      // Si no hay provincia seleccionada, limpiar el número
      _phoneNumber = '';
    }
    
    _clearError();
    notifyListeners();
  }

  /// Actualizar número de teléfono (permite edición manual)
  void setPhoneNumber(String phoneNumber) {
    _phoneNumber = phoneNumber;
    _clearError();
    notifyListeners();
  }

  /// Validar número de teléfono
  bool isPhoneNumberValid() {
    if (_selectedCountryCode == '+54') {
      // Para Argentina, debe tener al menos 10 dígitos (9 + código de área + número)
      return _phoneNumber.isNotEmpty && _phoneNumber.length >= 10;
    } else {
      // Para otros países, validación básica
      return _phoneNumber.isNotEmpty && _phoneNumber.length >= 7;
    }
  }

  /// Obtener mensaje de error de validación
  String? getValidationError() {
    if (_phoneNumber.isEmpty) {
      if (_selectedCountryCode == '+54') {
        return 'Por favor selecciona una provincia e ingresa tu número';
      } else {
        return 'Por favor ingresa tu número de teléfono';
      }
    }
    
    if (_selectedCountryCode == '+54') {
      if (_phoneNumber.length < 10) {
        return 'El número debe tener al menos 10 dígitos';
      }
      if (!_phoneNumber.startsWith('9')) {
        return 'El número debe comenzar con 9 (celular)';
      }
    } else {
      if (_phoneNumber.length < 7) {
        return 'El número debe tener al menos 7 dígitos';
      }
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
    _selectedProvinceCode = '';
    _clearError();
    notifyListeners();
  }

  /// Obtener el nombre de la provincia seleccionada
  String get selectedProvinceName {
    if (_selectedProvinceCode.isEmpty) return 'Seleccionar provincia';
    
    final province = _provinces.firstWhere(
      (p) => p['code'] == _selectedProvinceCode,
      orElse: () => {'name': 'Seleccionar provincia', 'code': ''},
    );
    return province['name']!;
  }

  /// Verificar si el país seleccionado es Argentina
  bool get isArgentina => _selectedCountryCode == '+54';

  /// Verificar si debe mostrar el selector de provincias
  bool get shouldShowProvinces => isArgentina;
}