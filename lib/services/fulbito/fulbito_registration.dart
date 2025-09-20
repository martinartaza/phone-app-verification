import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../models/network.dart';
import '../../utils/server_error_handler.dart';

class FulbitoRegistrationService {
  Future<Map<String, dynamic>> getFulbitoRegistration(String token, int fulbitoId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/fulbito/$fulbitoId/registrations/');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    // Verificar si hay errores del servidor
    if (ServerErrorHandler.isServerError(response) || 
        ServerErrorHandler.isServerDown(response) || 
        ServerErrorHandler.isMaintenanceMode(response)) {
      throw Exception('MAINTENANCE_MODE');
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load registration data: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded;
  }
}
