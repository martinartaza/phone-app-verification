import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/server_error_handler.dart';

class InviteGuestPlayerService {
  
  /// Mapea las habilidades del hexágono al formato de la API
  static Map<String, int> _mapSkillsToApiFormat(Map<String, double> skills) {
    return {
      'speed': skills['velocidad']?.round() ?? 50,
      'passing': skills['pases']?.round() ?? 50,
      'stamina': skills['resistencia']?.round() ?? 50,
      'shooting': skills['tiro_arco']?.round() ?? 50,
      'defending': skills['defensa']?.round() ?? 50,
      'dribbling': skills['gambeta']?.round() ?? 50,
    };
  }

  /// Invita a un jugador invitado a un fulbito
  static Future<Map<String, dynamic>> inviteGuestPlayer({
    required String token,
    required int fulbitoId,
    required String guestName,
    required Map<String, double> skills,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.getFulbitoRegisterInviteUrl(fulbitoId));
      
      // Mapear las habilidades al formato de la API
      final mappedSkills = _mapSkillsToApiFormat(skills);
      
      final body = {
        'guest_name': guestName,
        'skills': mappedSkills,
      };

      print('🔍 [InviteGuestPlayerService] Invitando jugador invitado:');
      print('🔍 URL: $url');
      print('🔍 Body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('🔍 HTTP Status: ${response.statusCode}');
      print('🔍 Response Body: ${response.body}');

      // Verificar si hay errores del servidor
      if (ServerErrorHandler.isServerError(response) || 
          ServerErrorHandler.isServerDown(response) || 
          ServerErrorHandler.isMaintenanceMode(response)) {
        return {
          'success': false,
          'message': 'El servidor está temporalmente no disponible. Por favor, intenta más tarde.',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? errorData['error'] ?? 'Error al invitar jugador',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error al invitar jugador (${response.statusCode})',
          };
        }
      }
    } catch (e) {
      print('❌ [InviteGuestPlayerService] Error: $e');
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }
}
