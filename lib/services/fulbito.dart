import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/fulbito_creation.dart';

class FulbitoService {
  Future<bool> createFulbito(String token, FulbitoCreation fulbito) async {
    try {
      final url = Uri.parse(ApiConfig.createFulbitoUrl);
      
      print('⚽ API CALL - POST ${ApiConfig.createFulbitoEndpoint}');
      print('⚽ Headers: Authorization: Bearer $token');
      print('⚽ Body: ${jsonEncode(fulbito.toJson())}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(fulbito.toJson()),
      );

      print('⚽ Response Status: ${response.statusCode}');
      print('⚽ Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Fulbito created successfully');
        return true;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error creating fulbito: $e');
      return false;
    }
  }

  Future<bool> updateFulbito(String token, int fulbitoId, Map<String, dynamic> updates) async {
    try {
      final url = Uri.parse(ApiConfig.getUpdateFulbitoUrl(fulbitoId));
      
      print('⚽ API CALL - PUT ${ApiConfig.updateFulbitoEndpoint}$fulbitoId/update/');
      print('⚽ Headers: Authorization: Bearer $token');
      print('⚽ Body: ${jsonEncode(updates)}');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updates),
      );

      print('⚽ Response Status: ${response.statusCode}');
      print('⚽ Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Fulbito updated successfully');
        return true;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error updating fulbito: $e');
      return false;
    }
  }

  Future<bool> deleteFulbito(String token, int fulbitoId) async {
    try {
      final url = Uri.parse(ApiConfig.getDeleteFulbitoUrl(fulbitoId));
      
      print('⚽ API CALL - DELETE ${ApiConfig.deleteFulbitoEndpoint}$fulbitoId/delete/');
      print('⚽ Headers: Authorization: Bearer $token');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('⚽ Response Status: ${response.statusCode}');
      print('⚽ Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Fulbito deleted successfully');
        return true;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error deleting fulbito: $e');
      return false;
    }
  }

  Future<bool> setTeams({
    required String token,
    required int fulbitoId,
    required String matchDate,
    required List<Map<String, dynamic>> players,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.getFulbitoTeamsUrl(fulbitoId));

      final body = {
        'match_date': matchDate,
        'players': players,
      };

      print('🧩 API CALL - PUT /fulbito/$fulbitoId/teams/');
      print('🧩 URL: $url');
      print('🧩 Headers: Authorization: Bearer $token');
      print('🧩 Body: ${jsonEncode(body)}');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('🧩 Response Status: ${response.statusCode}');
      print('🧩 Response Body: ${response.body}');

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('❌ Error setting teams: $e');
      return false;
    }
  }
}
