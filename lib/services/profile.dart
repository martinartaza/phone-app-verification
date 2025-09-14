import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class ProfileService {
  static const String _profileKey = 'user_profile';

  Future<bool> createProfile(UserProfile profile, String token) async {
    try {
      // TODO: Implementar llamada real al API
      // final url = Uri.parse('${ApiConfig.baseUrl}/api/profile/create/');
      // 
      // String? photoBase64;
      // if (profile.photoPath != null) {
      //   final bytes = await File(profile.photoPath!).readAsBytes();
      //   photoBase64 = base64Encode(bytes);
      // }
      // 
      // final response = await http.post(
      //   url,
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer $token',
      //   },
      //   body: jsonEncode({
      //     'name': profile.name,
      //     'age': profile.age,
      //     'photo_base64': photoBase64,
      //     'skills': {
      //       'velocidad': profile.skills['velocidad'],
      //       'resistencia': profile.skills['resistencia'],
      //       'tiro': profile.skills['tiro'],
      //       'gambeta': profile.skills['gambeta'],
      //       'pases': profile.skills['pases'],
      //     },
      //     'is_goalkeeper': profile.isGoalkeeper,
      //   }),
      // );
      // 
      // if (response.statusCode == 201) {
      //   final data = jsonDecode(response.body);
      //   // Procesar respuesta del servidor
      //   return true;
      // }

      // Mock: Simular éxito después de 2 segundos
      await Future.delayed(const Duration(seconds: 2));
      print('📤 MOCK API CALL - POST /api/profile/create/');
      print('📤 Headers: Authorization: Bearer $token');
      print('📤 Body: ${jsonEncode({
        'name': profile.name,
        'age': profile.age,
        'photo_base64': profile.photoPath != null ? '[BASE64_PHOTO_DATA]' : null,
        'skills': profile.skills,
        'is_goalkeeper': profile.isGoalkeeper,
      })}');
      print('📥 Response: {user_skills: ${profile.skills}, average_skills: {all: 0}, profile_completed: true}');
      
      return true;
    } catch (e) {
      print('❌ Error creating profile: $e');
      return false;
    }
  }

  Future<UserProfile?> getProfile(String token) async {
    try {
      // TODO: Implementar llamada real al API
      // final url = Uri.parse('${ApiConfig.baseUrl}/api/profile/me/');
      // 
      // final response = await http.get(
      //   url,
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //   },
      // );
      // 
      // if (response.statusCode == 200) {
      //   final data = jsonDecode(response.body);
      //   return UserProfile.fromJson(data);
      // }

      // Mock: Intentar cargar desde almacenamiento local
      final localProfile = await getProfileLocally();
      if (localProfile != null) {
        print('📥 MOCK API CALL - GET /api/profile/me/');
        print('📥 Headers: Authorization: Bearer $token');
        print('📥 Response: Profile loaded from local storage');
        return localProfile;
      }

      return null;
    } catch (e) {
      print('❌ Error getting profile: $e');
      return null;
    }
  }

  Future<void> saveProfileLocally(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toJson());
      await prefs.setString(_profileKey, profileJson);
      print('💾 Profile saved locally');
    } catch (e) {
      print('❌ Error saving profile locally: $e');
    }
  }

  Future<UserProfile?> getProfileLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);
      
      if (profileJson != null) {
        final profileData = jsonDecode(profileJson);
        return UserProfile.fromJson(profileData);
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting profile locally: $e');
      return null;
    }
  }

  Future<void> clearProfileLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
      print('🗑️ Profile cleared locally');
    } catch (e) {
      print('❌ Error clearing profile locally: $e');
    }
  }
}