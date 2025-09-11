import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  static Future<bool> createUser(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createUserUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',  // ← Agregar este header
        },
        body: jsonEncode({
          'phone_number': phoneNumber,
        }),
      );

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');  // ← Ver el error específico

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
  
  static Future<bool> verifyUser(String phoneNumber, String code) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyUserUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone_number': phoneNumber,
          'code': code,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error verifying user: $e');
      return false;
    }
  }
}