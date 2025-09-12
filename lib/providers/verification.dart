import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/auth.dart' as auth_service;

class VerificationProvider extends ChangeNotifier {
  // Estado del timer de reenvío
  int _resendTimer = 55;
  Timer? _timer;
  bool _canResend = false;
  
  // Estado de verificación
  bool _isVerifying = false;
  String? _errorMessage;
  
  // Getters
  int get resendTimer => _resendTimer;
  bool get canResend => _canResend;
  bool get isVerifying => _isVerifying;
  String? get errorMessage => _errorMessage;

  /// Iniciar el timer de reenvío
  void startResendTimer() {
    _resendTimer = 55;
    _canResend = false;
    notifyListeners();
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        _resendTimer--;
        notifyListeners();
      } else {
        _canResend = true;
        timer.cancel();
        notifyListeners();
      }
    });
  }

  /// Reenviar código de verificación
  Future<bool> resendCode(String phoneNumber) async {
    if (!_canResend) return false;
    
    try {
      final success = await auth_service.AuthService.createUser(phoneNumber);
      if (success) {
        startResendTimer();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Error reenviando código: $e');
      return false;
    }
  }

  /// Validar que el código esté completo
  bool isCodeComplete(List<String> codeDigits) {
    return codeDigits.every((digit) => digit.isNotEmpty) && codeDigits.length == 6;
  }

  /// Obtener código como string
  String getCodeAsString(List<String> codeDigits) {
    return codeDigits.join();
  }

  /// Limpiar campos de código
  void clearCode() {
    _clearError();
    notifyListeners();
  }

  /// Establecer estado de verificación
  void setVerifying(bool verifying) {
    _isVerifying = verifying;
    notifyListeners();
  }

  // Métodos privados
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}