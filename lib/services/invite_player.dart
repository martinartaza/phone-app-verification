import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/network_connection.dart';
import 'api_client.dart';

class InvitePlayerService {
  /// Invita a un usuario a la red (API v2)
  /// Retorna NetworkInviteResponse con status, message y data
  static Future<NetworkInviteResponse?> invitePlayer({
    required String token,
    required String phoneNumber,
    required String message,
  }) async {
    try {
      print('🌐 API CALL - POST ${ApiConfig.invitePlayerEndpoint}');
      print('🌐 Headers: Authorization: Bearer $token');
      print('🌐 Body: {phone_number: $phoneNumber, message: $message}');

      final response = await http.post(
        Uri.parse(ApiConfig.invitePlayerUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'phone_number': phoneNumber,
          'message': message,
        }),
      );

      print('🌐 Response Status: ${response.statusCode}');
      print('🌐 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('🌐 Parsed response data: $responseData');
        final result = NetworkInviteResponse.fromJson(responseData);
        print('🌐 NetworkInviteResponse created: status=${result.status}, message=${result.message}');
        return result;
      } else if (response.statusCode == 400) {
        // Errores de validación o reglas de negocio
        try {
          final responseData = jsonDecode(response.body);
          return NetworkInviteResponse(
            status: 'error',
            message: responseData['message'] ?? 'Error en la solicitud',
          );
        } catch (e) {
          return NetworkInviteResponse(
            status: 'error',
            message: 'Error en la solicitud (400)',
          );
        }
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return NetworkInviteResponse(
          status: 'error',
          message: 'Error del servidor (${response.statusCode})',
        );
      }
    } catch (e) {
      print('❌ Error inviting player: $e');
      return NetworkInviteResponse(
        status: 'error',
        message: 'Error de conexión: $e',
      );
    }
  }

  /// Acepta una conexión de red (API v2)
  static Future<bool> acceptConnection({
    required String token,
    required int connectionId,
    ApiClient? apiClient,
  }) async {
    try {
      if (apiClient != null) {
        // Usar ApiClient con sync automático
        final response = await apiClient.put(
          ApiConfig.getAcceptConnectionUrl(connectionId),
          triggerSync: true,
        );
        
        if (response.statusCode == 200) {
          print('✅ Connection accepted successfully');
          return true;
        } else {
          print('❌ API Error: ${response.statusCode} - ${response.body}');
          return false;
        }
      } else {
        // Fallback: uso directo de http (sin sync automático)
        print('🌐 API CALL - PUT ${ApiConfig.acceptConnectionEndpoint}$connectionId/accept/');
        print('🌐 Headers: Authorization: Bearer $token');

        final response = await http.put(
          Uri.parse(ApiConfig.getAcceptConnectionUrl(connectionId)),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        print('🌐 Response Status: ${response.statusCode}');
        print('🌐 Response Body: ${response.body}');

        if (response.statusCode == 200) {
          print('✅ Connection accepted successfully');
          return true;
        } else {
          print('❌ API Error: ${response.statusCode} - ${response.body}');
          return false;
        }
      }
    } catch (e) {
      print('❌ Error accepting connection: $e');
      return false;
    }
  }

  /// Rechaza una conexión de red (API v2)
  static Future<bool> rejectConnection({
    required String token,
    required int connectionId,
    ApiClient? apiClient,
  }) async {
    try {
      if (apiClient != null) {
        // Usar ApiClient con sync automático
        final response = await apiClient.put(
          ApiConfig.getRejectConnectionUrl(connectionId),
          triggerSync: true,
        );
        
        if (response.statusCode == 200) {
          print('✅ Connection rejected successfully');
          return true;
        } else {
          print('❌ API Error: ${response.statusCode} - ${response.body}');
          return false;
        }
      } else {
        // Fallback: uso directo de http (sin sync automático)
        print('🌐 API CALL - PUT ${ApiConfig.rejectConnectionEndpoint}$connectionId/reject/');
        print('🌐 Headers: Authorization: Bearer $token');

        final response = await http.put(
          Uri.parse(ApiConfig.getRejectConnectionUrl(connectionId)),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        print('🌐 Response Status: ${response.statusCode}');
        print('🌐 Response Body: ${response.body}');

        if (response.statusCode == 200) {
          print('✅ Connection rejected successfully');
          return true;
        } else {
          print('❌ API Error: ${response.statusCode} - ${response.body}');
          return false;
        }
      }
    } catch (e) {
      print('❌ Error rejecting connection: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> inviteToFulbito({
    required String token,
    required int fulbitoId,
    required List<String> phoneNumbers,
  }) async {
    try {
      print('🌐 API CALL - POST ${ApiConfig.getFulbitoInviteUrl(fulbitoId)}');
      print('🌐 Headers: Authorization: Bearer $token');
      print('🌐 Body: {phone_numbers: $phoneNumbers}');

      // TODO: La API v2 requiere user_id en lugar de phone_numbers
      // Por ahora, usar la API vieja hasta que implementemos la conversión de phone -> user_id
      final response = await http.post(
        Uri.parse(ApiConfig.getFulbitoInviteUrl(fulbitoId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'phone_numbers': phoneNumbers,
        }),
      );

      print('🌐 Response Status: ${response.statusCode}');
      print('🌐 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'error': responseData['message'] ?? 'Error al enviar invitaciones',
        };
      }
    } catch (e) {
      print('❌ Error inviting to fulbito: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }
}
