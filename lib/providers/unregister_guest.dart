import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/unregister_guest.dart';
import '../widgets/maintenance_modal.dart';
import 'auth.dart' as auth_provider;
import 'invitations.dart';

class UnregisterGuestProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<Map<String, dynamic>> unregisterGuest({
    required String token,
    required int fulbitoId,
    required String guestName,
    required BuildContext context,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await UnregisterGuestService.unregisterGuest(
        token: token,
        fulbitoId: fulbitoId,
        guestName: guestName,
      );

      _isLoading = false;
      notifyListeners();

      if (result['success'] == true) {
        // Mostrar modal de éxito
        if (context.mounted) {
          _showUnregisterSuccessModal(context, guestName);
          
          // Recargar datos para actualizar el estado (igual que el unregister normal)
          final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
          final invitationsProvider = Provider.of<InvitationsProvider>(context, listen: false);
          if (authProvider.token != null) {
            invitationsProvider.load(authProvider.token!);
          }
        }
        return result;
      } else {
        // Mostrar modal de error o mantenimiento
        if (context.mounted) {
          if (result['isMaintenance'] == true) {
            _showMaintenanceModal(context);
          } else {
            _showUnregisterErrorModal(context, result['message'] ?? 'Error desconocido');
          }
        }
        return result;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      if (context.mounted) {
        _showUnregisterErrorModal(context, 'Error inesperado: ${e.toString()}');
      }
      return {
        'success': false,
        'isError': true,
        'message': 'Error inesperado: ${e.toString()}',
      };
    }
  }

  void _showUnregisterSuccessModal(BuildContext context, String guestName) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Auto-cerrar después de 3 segundos (más rápido que el unregister normal)
        Future.delayed(const Duration(seconds: 3), () {
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
              border: Border.all(
                color: const Color(0xFFC3E6CB),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de éxito
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                // Título
                const Text(
                  '¡Desinscripción Exitosa!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF155724),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                // Mensaje
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'El invitado $guestName ha sido desinscrito exitosamente del fulbito.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF155724),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                // Botón
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUnregisterErrorModal(BuildContext context, String message) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Error en la Desinscripción',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMaintenanceModal(BuildContext context) {
    if (!context.mounted) return;

    MaintenanceModal.show(context);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
