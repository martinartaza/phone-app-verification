import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../providers/auth.dart' as auth_provider;
import '../providers/invitations.dart';
import '../providers/sync_provider.dart';
import '../services/api_client.dart';

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

      final response = await _callRegistrationAPI(context, authProvider.token!, fulbitoId);
      
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

  Future<bool> cancelRegistration(BuildContext context, int fulbitoId) async {
    _setLoading(true);

    try {
      final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
      if (authProvider.token == null) {
        _setError('No hay token de autenticación');
        return false;
      }

      final response = await _callCancelRegistrationAPI(context, authProvider.token!, fulbitoId);
      
      if (response['success']) {
        // Mostrar modal de éxito
        _showCancellationSuccessModal(context, response['data']);
        
        // Recargar datos para actualizar el estado
        final invitationsProvider = Provider.of<InvitationsProvider>(context, listen: false);
        invitationsProvider.load(authProvider.token!);
        
        _setLoading(false);
        return true;
      } else {
        // Mostrar modal de error
        _showCancellationErrorModal(context, response['message'] ?? 'Error al cancelar inscripción');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _showCancellationErrorModal(context, 'Error: $e');
      _setLoading(false);
      return false;
    }
  }

  // Método específico para cancelar desde el home con modal de confirmación
  Future<void> cancelRegistrationFromHome(BuildContext context, int fulbitoId) async {
    // Mostrar modal de confirmación
    final bool? confirmed = await _showCancelRegistrationConfirmationDialog(context);
    
    if (confirmed == true) {
      // Si el usuario confirma, proceder con la cancelación
      await cancelRegistration(context, fulbitoId);
    }
    // Si el usuario cancela (confirmed == false o null), no hacer nada
  }

  // Modal de confirmación para cancelar inscripción
  Future<bool?> _showCancelRegistrationConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Cancelar Inscripción',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '¿Estás seguro que quieres cancelar tu inscripción?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'No',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Sí',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _callRegistrationAPI(BuildContext context, String token, int fulbitoId) async {
    final url = ApiConfig.getFulbitoRegisterUrl(fulbitoId);
    
    // Usar ApiClient con sync automático
    final apiClient = ApiClient(
      token: token,
      onSyncRequired: (token) async {
        print('🔄 [RegistrationProvider] Sync triggered by ApiClient');
        print('🔄 [RegistrationProvider] Context available: ${context != null}');
        try {
          // Ejecutar sync real
          final syncProvider = Provider.of<SyncProvider>(context, listen: false);
          print('🔄 [RegistrationProvider] SyncProvider obtained, starting sync...');
          await syncProvider.performIncrementalSync(token);
          print('✅ [RegistrationProvider] Sync completed successfully');
        } catch (e) {
          print('❌ [RegistrationProvider] Error during sync: $e');
        }
      },
    );
    
    final response = await apiClient.post(url);

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

  Future<Map<String, dynamic>> _callCancelRegistrationAPI(BuildContext context, String token, int fulbitoId) async {
    final url = ApiConfig.getFulbitoUnregisterUrl(fulbitoId);
    
    // Usar ApiClient con sync automático
    final apiClient = ApiClient(
      token: token,
      onSyncRequired: (token) async {
        print('🔄 [RegistrationProvider] Sync triggered by ApiClient');
        print('🔄 [RegistrationProvider] Context available: ${context != null}');
        try {
          // Ejecutar sync real
          final syncProvider = Provider.of<SyncProvider>(context, listen: false);
          print('🔄 [RegistrationProvider] SyncProvider obtained, starting sync...');
          await syncProvider.performIncrementalSync(token);
          print('✅ [RegistrationProvider] Sync completed successfully');
        } catch (e) {
          print('❌ [RegistrationProvider] Error during sync: $e');
        }
      },
    );
    
    final response = await apiClient.delete(url);

    print('🔍 Cancel HTTP Status: ${response.statusCode}');
    print('🔍 Cancel Response Body: ${response.body}');

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
          'message': data['message'] ?? 'Error al cancelar inscripción',
        };
      }
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Error al cancelar inscripción',
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

  void _showCancellationSuccessModal(BuildContext context, Map<String, dynamic> data) {
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
              color: const Color(0xFFD4EDDA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF28A745), width: 3),
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
                  // Icono de éxito
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF28A745),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF28A745).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Título de éxito
                  Text(
                    'Inscripción Cancelada',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF155724),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Mensaje descriptivo
                  Text(
                    'Tu inscripción ha sido cancelada exitosamente',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF155724),
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
                        backgroundColor: const Color(0xFF28A745),
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

  void _showCancellationErrorModal(BuildContext context, String errorMessage) {
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
                    'Error al Cancelar',
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

  /// Determina qué botón mostrar basado en el estado de inscripción del usuario
  bool shouldShowInscriptionButton({
    required List<Map<String, dynamic>> players,
    required int? currentUserId,
    required bool registrationOpen,
    bool? userRegistered, // Nuevo parámetro del sync
  }) {
    print('🔍 shouldShowInscriptionButton - Debug:');
    print('  - currentUserId: $currentUserId');
    print('  - registrationOpen: $registrationOpen');
    print('  - userRegistered: $userRegistered');
    print('  - players: $players');
    
    // Si no hay usuario actual, no mostrar botón de inscripción
    if (currentUserId == null) {
      print('  - Resultado: false (no currentUserId)');
      return false;
    }
    
    // Si la inscripción está cerrada, no mostrar botón de inscripción
    if (!registrationOpen) {
      print('  - Resultado: false (registration closed)');
      return false;
    }
    
    // PRIORIDAD: Usar userRegistered del sync si está disponible
    if (userRegistered != null) {
      print('  - Usando userRegistered del sync: $userRegistered');
      print('  - DEBUG: userRegistered es de tipo: ${userRegistered.runtimeType}');
      final bool result = !userRegistered; // Si está registrado, NO mostrar botón de inscripción
      print('  - Resultado final: $result (${result ? "INSCRIPCIÓN" : "DESINSCRIPCIÓN"})');
      print('  - LÓGICA: userRegistered=$userRegistered → !userRegistered=$result');
      return result;
    }
    
    // FALLBACK: Verificar si el usuario está inscrito como "player" o "substitute" (no como "guest")
    final bool isUserRegisteredAsPlayer = players.any((player) => 
        player['userid'] == currentUserId && 
        player['type'] != 'guest'
    );
    
    print('  - isUserRegisteredAsPlayer (fallback): $isUserRegisteredAsPlayer');
    
    // Si está inscrito como player/substitute, mostrar botón de desinscripción
    // Si NO está inscrito como player/substitute, mostrar botón de inscripción
    final bool result = !isUserRegisteredAsPlayer;
    print('  - Resultado final (fallback): $result (${result ? "INSCRIPCIÓN" : "DESINSCRIPCIÓN"})');
    
    return result;
  }

  /// Obtiene la información del usuario inscrito
  Map<String, dynamic>? getUserPlayerInfo({
    required List<Map<String, dynamic>> players,
    required int? currentUserId,
  }) {
    print('🔍 getUserPlayerInfo - Debug:');
    print('  - currentUserId: $currentUserId');
    print('  - players: $players');
    
    if (currentUserId == null) {
      print('  - Resultado: null (no currentUserId)');
      return null;
    }
    
    try {
      final result = players.firstWhere((player) => 
          player['userid'] == currentUserId && 
          player['type'] != 'guest'
      );
      print('  - Resultado: $result');
      return result;
    } catch (e) {
      print('  - Resultado: null (usuario no encontrado como player/substitute)');
      return null;
    }
  }
}
