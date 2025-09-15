import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../config/api_config.dart';

class ProfileService {
  static const String _profileKey = 'user_profile';

  Future<bool> createProfile(UserProfile profile, String token) async {
    try {
      final url = Uri.parse(ApiConfig.updateProfileUrl);
      
      // Preparar self_perception según el formato esperado por la API (en inglés)
      final selfPerception = {
        'speed': profile.skills['velocidad']?.round() ?? 50,
        'stamina': profile.skills['resistencia']?.round() ?? 50,
        'shooting': profile.skills['tiro']?.round() ?? 50,
        'dribbling': profile.skills['gambeta']?.round() ?? 50,
        'passing': profile.skills['pases']?.round() ?? 50,
        'defending': profile.skills['defensa']?.round() ?? 50,
      };

      http.Response response;

      if (profile.photoPath != null) {
        // Si hay foto, usar multipart/form-data
        final request = http.MultipartRequest('PUT', url);
        
        request.headers['Authorization'] = 'Bearer $token';
        
        // Agregar campos del perfil
        request.fields['firstname'] = profile.name;
        request.fields['age'] = profile.age.toString();
        request.fields['is_goalkeeper'] = profile.isGoalkeeper.toString();
        request.fields['is_forward'] = profile.isStriker.toString();
        request.fields['is_midfielder'] = profile.isMidfielder.toString();
        request.fields['is_defender'] = profile.isDefender.toString();
        request.fields['self_perception'] = jsonEncode(selfPerception);
        
        // Agregar foto
        final file = File(profile.photoPath!);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath('photo', file.path));
        }
        
        print('📤 API CALL - PUT ${ApiConfig.updateProfileEndpoint} (multipart)');
        print('📤 Headers: Authorization: Bearer $token');
        print('📤 Fields: ${request.fields}');
        print('📤 Photo: ${profile.photoPath}');
        
        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Si no hay foto, usar JSON
        final body = {
          'firstname': profile.name,
          'age': profile.age,
          'is_goalkeeper': profile.isGoalkeeper,
          'is_forward': profile.isStriker,
          'is_midfielder': profile.isMidfielder,
          'is_defender': profile.isDefender,
          'self_perception': selfPerception,
        };

        print('📤 API CALL - PUT ${ApiConfig.updateProfileEndpoint} (JSON)');
        print('📤 Headers: Authorization: Bearer $token');
        print('📤 Body: ${jsonEncode(body)}');

        response = await http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        );
      }

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Éxito - procesar respuesta si es necesario
        try {
          final data = jsonDecode(response.body);
          print('✅ Profile updated successfully: $data');
        } catch (e) {
          print('✅ Profile updated successfully (no JSON response)');
        }
        return true;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error creating profile: $e');
      return false;
    }
  }

  Future<UserProfile?> getProfile(String token) async {
    try {
      final url = Uri.parse(ApiConfig.updateProfileUrl);
      
      print('📥 API CALL - GET ${ApiConfig.updateProfileEndpoint}');
      print('📥 Headers: Authorization: Bearer $token');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          final data = responseData['data'];
          
          // Mapear self_perception de inglés a español para uso interno
          final selfPerception = data['self_perception'] as Map<String, dynamic>? ?? {};
          final mappedSkills = <String, double>{
            'velocidad': (selfPerception['speed'] ?? 50).toDouble(),
            'resistencia': (selfPerception['stamina'] ?? 50).toDouble(),
            'tiro': (selfPerception['shooting'] ?? 50).toDouble(),
            'gambeta': (selfPerception['dribbling'] ?? 50).toDouble(),
            'pases': (selfPerception['passing'] ?? 50).toDouble(),
            'defensa': (selfPerception['defending'] ?? 50).toDouble(),
          };
          
          // Mapear average_opinion de inglés a español para uso interno
          final averageOpinion = data['average_opinion'] as Map<String, dynamic>? ?? {};
          final mappedAverageSkills = <String, double>{
            'velocidad': (averageOpinion['speed'] ?? 0).toDouble(),
            'resistencia': (averageOpinion['stamina'] ?? 0).toDouble(),
            'tiro': (averageOpinion['shooting'] ?? 0).toDouble(),
            'gambeta': (averageOpinion['dribbling'] ?? 0).toDouble(),
            'pases': (averageOpinion['passing'] ?? 0).toDouble(),
            'defensa': (averageOpinion['defending'] ?? 0).toDouble(),
          };
          
          // Construir URL completa de la foto si existe
          String? fullPhotoUrl;
          if (data['photo_url'] != null && data['photo_url'].toString().isNotEmpty) {
            final photoPath = data['photo_url'].toString();
            fullPhotoUrl = photoPath.startsWith('http') 
                ? photoPath 
                : '${ApiConfig.baseUrl}$photoPath';
          }
          
          final profile = UserProfile(
            // El backend devuelve first_name; usar fallback a firstname por compatibilidad
            name: data['first_name'] ?? data['firstname'] ?? '',
            age: data['age'] ?? 30,
            photoUrl: fullPhotoUrl,
            skills: mappedSkills,
            averageSkills: mappedAverageSkills,
            isGoalkeeper: data['is_goalkeeper'] ?? false,
            isStriker: data['is_forward'] ?? false,
            isMidfielder: data['is_midfielder'] ?? false,
            isDefender: data['is_defender'] ?? false,
            profileCompleted: true,
            numberOfOpinions: data['number_of_opinions'] ?? 0,
          );
          
          print('✅ Profile loaded successfully from server');
          return profile;
        }
      }
      
      // Si falla la API, intentar cargar desde almacenamiento local
      print('⚠️ API failed, trying local storage...');
      final localProfile = await getProfileLocally();
      if (localProfile != null) {
        print('📥 Profile loaded from local storage');
        return localProfile;
      }

      return null;
    } catch (e) {
      print('❌ Error getting profile: $e');
      
      // En caso de error, intentar cargar desde almacenamiento local
      try {
        final localProfile = await getProfileLocally();
        if (localProfile != null) {
          print('📥 Fallback: Profile loaded from local storage');
          return localProfile;
        }
      } catch (localError) {
        print('❌ Error loading from local storage: $localError');
      }
      
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