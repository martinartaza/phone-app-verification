import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../providers/auth.dart' as auth_provider;
import '../providers/invitations.dart';

class RegistrationProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> registerForFulbito(BuildContext context, int fulbitoId) async {
    _setLoading(true);

    try {
      final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
      if (authProvider.token == null) {
        _setError('No hay token de autenticación');
        return false;
      }

      final response = await _callRegistrationAPI(authProvider.token!, fulbitoId);
      
      if (response['success']) {
        // Mostrar modal de éxito
        _showRegistrationSuccessModal(context, response['data']);
        
        // Recargar datos para actualizar el estado
        final invitationsProvider = Provider.of<InvitationsProvider>(context, listen: false);
        invitationsProvider.load(authProvider.token!);
        
        _setLoading(false);
        return true;
      } else {
        // Mostrar modal de error
        _showRegistrationErrorModal(context, response['message'] ?? 'Error al inscribirse');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _showRegistrationErrorModal(context, 'Error: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<Map<String, dynamic>> _callRegistrationAPI(String token, int fulbitoId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/fulbito/$fulbitoId/register/');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('🔍 HTTP Status: ${response.statusCode}');
    print('🔍 Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al inscribirse',
        };
      }
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Error al inscribirse',
      };
    }
  }

  void _showRegistrationSuccessModal(BuildContext context, Map<String, dynamic> data) {
    final position = data['position'] ?? 0;
    final role = data['role'] ?? 'player';
    final registeredAt = data['registered_at'] ?? '';
    final isSubstitute = role == 'substitute';
    
    // Determinar colores según el rol
    final backgroundColor = isSubstitute ? const Color(0xFFFFF3CD) : const Color(0xFFD4EDDA);
    final borderColor = isSubstitute ? const Color(0xFFFFC107) : const Color(0xFF28A745);
    final iconColor = isSubstitute ? const Color(0xFFFFC107) : const Color(0xFF28A745);
    final textColor = isSubstitute ? const Color(0xFF856404) : const Color(0xFF155724);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Auto-cerrar después de 5 segundos
        Future.delayed(const Duration(seconds: 5), () {
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono de éxito más grande
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      isSubstitute ? Icons.schedule : Icons.check_circle,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Título más grande
                  Text(
                    isSubstitute ? ApiConfig.registrationSubstituteTitle : ApiConfig.registrationSuccessTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Mensaje descriptivo
                  Text(
                    isSubstitute ? ApiConfig.registrationSubstituteMessage : ApiConfig.registrationSuccessMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Información de inscripción más grande
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Posición:', '$position'),
                        const SizedBox(height: 12),
                        _buildInfoRow('Rol:', isSubstitute ? 'Suplente' : 'Jugador'),
                        if (registeredAt.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow('Hora de inscripción:', _formatDateTime(registeredAt)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón OK más grande
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: iconColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRegistrationErrorModal(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Auto-cerrar después de 5 segundos
        Future.delayed(const Duration(seconds: 5), () {
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              color: const Color(0xFFF8D7DA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDC3545), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono de error
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC3545),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC3545).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Título de error
                  Text(
                    ApiConfig.registrationErrorTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF721C24),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Mensaje de error
                  Text(
                    errorMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF721C24),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón OK
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC3545),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String dateTime) {
    try {
      final DateTime parsed = DateTime.parse(dateTime);
      final String formatted = '${parsed.day}/${parsed.month}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      return formatted;
    } catch (e) {
      return dateTime;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
