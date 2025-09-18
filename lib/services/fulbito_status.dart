import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/server_error_handler.dart';

class FulbitoStatusService {
  static Future<Map<String, dynamic>> updateFulbitoStatus({
    required String token,
    required int invitationId,
    required String status, // 'accepted' o 'rejected'
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.getFulbitoStatusUrl(invitationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      // Verificar si hay errores del servidor
      if (ServerErrorHandler.isServerError(response) || 
          ServerErrorHandler.isServerDown(response) || 
          ServerErrorHandler.isMaintenanceMode(response)) {
        return {
          'success': false,
          'error': 'MAINTENANCE_MODE',
        };
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Error al actualizar fulbito',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }
}
