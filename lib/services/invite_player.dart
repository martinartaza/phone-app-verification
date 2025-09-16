import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class InvitePlayerService {
  static Future<Map<String, dynamic>> invitePlayer({
    required String token,
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.invitePlayerUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'phone_number_receiver': phoneNumber,
          'message': message,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
          'shouldOpenWhatsApp': responseData['message'] == 'user not found',
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Error al enviar invitación',
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
