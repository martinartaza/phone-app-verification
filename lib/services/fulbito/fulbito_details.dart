import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class FulbitoDetailsService {
  /// Obtener detalles completos del fulbito incluyendo jugadores
  static Future<Map<String, dynamic>?> getFulbitoDetails({
    required String token,
    required int fulbitoId,
  }) async {
    try {
      print('🔍 API CALL - GET ${ApiConfig.getFulbitoDetailsUrl(fulbitoId)}');
      print('🔍 Headers: Authorization: Bearer $token');

      final response = await http.get(
        Uri.parse(ApiConfig.getFulbitoDetailsUrl(fulbitoId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔍 Response Status: ${response.statusCode}');
      print('🔍 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Fulbito details retrieved successfully');
        return responseData;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting fulbito details: $e');
      return null;
    }
  }
}

