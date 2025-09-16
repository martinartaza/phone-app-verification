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
}
