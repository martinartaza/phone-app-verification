import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class VoteService {
  Future<bool> submitVote(String token, String playerUuid, Map<String, double> vote) async {
    try {
      final url = Uri.parse(ApiConfig.getVotePlayerUrl(playerUuid));
      
      // Convertir las habilidades de español a inglés para la API
      final body = {
        'speed': vote['velocidad']?.round() ?? 50,
        'stamina': vote['resistencia']?.round() ?? 50,
        'shooting': vote['tiro']?.round() ?? 50,
        'dribbling': vote['gambeta']?.round() ?? 50,
        'passing': vote['pases']?.round() ?? 50,
        'defending': vote['defensa']?.round() ?? 50,
      };

      print('🗳️ API CALL - PUT ${ApiConfig.getVotePlayerUrl(playerUuid)}');
      print('🗳️ Headers: Authorization: Bearer $token');
      print('🗳️ Body: ${jsonEncode(body)}');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('🗳️ Response Status: ${response.statusCode}');
      print('🗳️ Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Vote submitted successfully');
        return true;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error submitting vote: $e');
      return false;
    }
  }
}

