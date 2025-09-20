import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/network.dart';
import '../../providers/registration.dart';
import '../../providers/auth.dart' as auth_provider;
import 'fulbito_provider.dart';

class FulbitoInscriptionProvider extends ChangeNotifier {
  Map<String, dynamic>? _selectedPlayer;
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get selectedPlayer => _selectedPlayer;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Seleccionar/deseleccionar jugador
  void selectPlayer(Map<String, dynamic>? player) {
    _selectedPlayer = player;
    notifyListeners();
  }

  void clearSelection() {
    _selectedPlayer = null;
    notifyListeners();
  }

  // Inscribirse en fulbito
  Future<bool> registerForFulbito(BuildContext context, int fulbitoId) async {
    print('🔍 [FulbitoInscriptionProvider] Iniciando inscripción para fulbito: $fulbitoId');
    _setLoading(true);

    try {
      final regProvider = Provider.of<RegistrationProvider>(context, listen: false);
      final success = await regProvider.registerForFulbito(context, fulbitoId);
      
      print('🔍 [FulbitoInscriptionProvider] Resultado de inscripción: $success');
      
      if (success) {
        print('🔍 [FulbitoInscriptionProvider] Inscripción exitosa, actualizando lista de jugadores...');
        
        // Actualizar la lista de jugadores inscritos en FulbitoProvider
        final fulbitoProvider = Provider.of<FulbitoProvider>(context, listen: false);
        final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
        
        print('🔍 [FulbitoInscriptionProvider] Token disponible: ${authProvider.token != null}');
        print('🔍 [FulbitoInscriptionProvider] Fulbito actual: ${fulbitoProvider.currentFulbito?.id}');
        
        if (authProvider.token != null && fulbitoProvider.currentFulbito != null) {
          print('🔍 [FulbitoInscriptionProvider] Recargando detalles del fulbito...');
          await fulbitoProvider.loadFulbitoDetails(
            fulbitoProvider.currentFulbito!, 
            authProvider.phoneNumber ?? '', 
            authProvider.token!
          );
          print('🔍 [FulbitoInscriptionProvider] Detalles del fulbito recargados');
        } else {
          print('🔍 [FulbitoInscriptionProvider] No se pudo recargar - token o fulbito nulos');
        }
      }
      
      _setLoading(false);
      return success;
    } catch (e) {
      print('🔍 [FulbitoInscriptionProvider] Error durante inscripción: $e');
      _setError('Error al inscribirse: $e');
      _setLoading(false);
      return false;
    }
  }

  // Cancelar inscripción
  Future<bool> cancelRegistration(BuildContext context, int fulbitoId) async {
    print('🔍 [FulbitoInscriptionProvider] Iniciando cancelación para fulbito: $fulbitoId');
    _setLoading(true);

    try {
      final regProvider = Provider.of<RegistrationProvider>(context, listen: false);
      final success = await regProvider.cancelRegistration(context, fulbitoId);
      
      print('🔍 [FulbitoInscriptionProvider] Resultado de cancelación: $success');
      
      if (success) {
        print('🔍 [FulbitoInscriptionProvider] Cancelación exitosa, actualizando lista de jugadores...');
        
        // Actualizar la lista de jugadores inscritos en FulbitoProvider
        final fulbitoProvider = Provider.of<FulbitoProvider>(context, listen: false);
        final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
        
        print('🔍 [FulbitoInscriptionProvider] Token disponible: ${authProvider.token != null}');
        print('🔍 [FulbitoInscriptionProvider] Fulbito actual: ${fulbitoProvider.currentFulbito?.id}');
        
        if (authProvider.token != null && fulbitoProvider.currentFulbito != null) {
          print('🔍 [FulbitoInscriptionProvider] Recargando detalles del fulbito...');
          await fulbitoProvider.loadFulbitoDetails(
            fulbitoProvider.currentFulbito!, 
            authProvider.phoneNumber ?? '', 
            authProvider.token!
          );
          print('🔍 [FulbitoInscriptionProvider] Detalles del fulbito recargados');
        } else {
          print('🔍 [FulbitoInscriptionProvider] No se pudo recargar - token o fulbito nulos');
        }
      }
      
      _setLoading(false);
      return success;
    } catch (e) {
      print('🔍 [FulbitoInscriptionProvider] Error durante cancelación: $e');
      _setError('Error al cancelar inscripción: $e');
      _setLoading(false);
      return false;
    }
  }

  // Convertir habilidades de jugadores a mapa
  Map<String, double> convertSkillsToMap(List<Map<String, dynamic>> players) {
    if (players.isEmpty) return {};
    
    // Calcular promedio de habilidades de todos los jugadores
    final skills = <String, List<double>>{};
    
    for (final player in players) {
      final averageSkills = player['averageSkills'] as Map<String, dynamic>?;
      if (averageSkills != null) {
        averageSkills.forEach((key, value) {
          if (value is num) {
            skills.putIfAbsent(key, () => []).add(value.toDouble());
          }
        });
      }
    }
    
    final result = <String, double>{};
    skills.forEach((key, values) {
      result[key] = values.reduce((a, b) => a + b) / values.length;
    });
    
    return result;
  }

  // Obtener habilidades del jugador seleccionado
  Map<String, double> getSelectedPlayerSkills() {
    if (_selectedPlayer == null) return {};
    
    final averageSkills = _selectedPlayer!['averageSkills'] as Map<String, dynamic>?;
    if (averageSkills == null) return {};
    
    return averageSkills.map((key, value) => MapEntry(key, value.toDouble()));
  }

  // Obtener título del hexágono
  String getHexagonTitle() {
    if (_selectedPlayer != null) {
      return 'Habilidades de ${_selectedPlayer!['username'] ?? 'Jugador'}';
    }
    return 'Habilidades Promedio';
  }

  // Formatear fecha de inicio de inscripción
  String formatRegistrationStartTime(String opensAt) {
    try {
      final date = DateTime.parse(opensAt);
      return '${date.day}/${date.month}/${date.year} a las ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return opensAt;
    }
  }

  // Formatear hora
  String formatTime(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  // Formatear fecha para pestaña
  String formatTabDate(String nextMatchDate) {
    if (nextMatchDate.isEmpty) return 'Inscribirse';
    
    try {
      final date = DateTime.parse(nextMatchDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return nextMatchDate;
    }
  }

  // Mostrar modal de cancelación
  void showCancelRegistrationDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'No',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
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


  // Métodos privados
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
