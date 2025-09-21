import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/server_error_handler.dart';

class UnregisterGuestService {
  static Future<Map<String, dynamic>> unregisterGuest({
    required String token,
    required int fulbitoId,
    required String guestName,
  }) async {
    try {
      final url = ApiConfig.getFulbitoUnregisterInviteUrl(fulbitoId);
      
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'guest_name': guestName,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Invitado desinscrito exitosamente',
          'data': responseData,
        };
      } else {
        // Manejar errores del servidor
        if (ServerErrorHandler.isServerError(response)) {
          return {
            'success': false,
            'isError': true,
            'isMaintenance': true,
            'message': 'El servidor no está disponible temporalmente',
          };
        } else if (ServerErrorHandler.isServerDown(response)) {
          return {
            'success': false,
            'isError': true,
            'isMaintenance': true,
            'message': 'El servidor está temporalmente fuera de servicio',
          };
        } else if (ServerErrorHandler.isMaintenanceMode(response)) {
          return {
            'success': false,
            'isError': true,
            'isMaintenance': true,
            'message': 'El servidor está en modo mantenimiento',
          };
        } else {
          return {
            'success': false,
            'isError': true,
            'message': responseData['message'] ?? 'Error desconocido',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'isError': true,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }
}
