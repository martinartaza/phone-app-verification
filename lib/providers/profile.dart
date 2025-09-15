import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile.dart';
import '../models/user_profile.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  UserProfile _profile = UserProfile();
  bool _isLoading = false;
  String? _error;

  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isNameValid {
    final name = _profile.name.trim();
    return name.length >= 4 && name.length <= 20 && !name.contains(' ');
  }

  bool get canSaveProfile {
    return isNameValid && !_isLoading;
  }

  void updateName(String name) {
    _profile = _profile.copyWith(name: name);
    _clearError();
    notifyListeners();
  }

  void updateAge(int age) {
    print('🔄 ProfileProvider updateAge:');
    print('  - old age: ${_profile.age}');
    print('  - new age: $age');
    _profile = _profile.copyWith(age: age);
    print('  - updated profile.age: ${_profile.age}');
    notifyListeners();
  }

  void updateSkill(String skillName, double value) {
    final updatedSkills = Map<String, double>.from(_profile.skills);
    updatedSkills[skillName] = value;
    _profile = _profile.copyWith(skills: updatedSkills);
    notifyListeners();
  }

  void updateIsGoalkeeper(bool isGoalkeeper) {
    _profile = _profile.copyWith(isGoalkeeper: isGoalkeeper);
    notifyListeners();
  }

  void updateIsStriker(bool isStriker) {
    _profile = _profile.copyWith(isStriker: isStriker);
    notifyListeners();
  }

  void updateIsMidfielder(bool isMidfielder) {
    _profile = _profile.copyWith(isMidfielder: isMidfielder);
    notifyListeners();
  }

  void updateIsDefender(bool isDefender) {
    _profile = _profile.copyWith(isDefender: isDefender);
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        _profile = _profile.copyWith(photoPath: image.path);
        notifyListeners();
      }
    } catch (e) {
      _setError('Error al seleccionar imagen: $e');
    }
  }

  Future<bool> saveProfile(String token) async {
    if (!canSaveProfile) {
      _setError('Llenar nombre de 4 a 20 caracteres (no puede ser espacio)');
      return false;
    }

    print('💾 ProfileProvider saveProfile:');
    print('  - profile.name: ${_profile.name}');
    print('  - profile.age: ${_profile.age}');
    print('  - profile.skills: ${_profile.skills}');
    print('  - profile.isGoalkeeper: ${_profile.isGoalkeeper}');
    print('  - profile.isStriker: ${_profile.isStriker}');
    print('  - profile.isMidfielder: ${_profile.isMidfielder}');
    print('  - profile.isDefender: ${_profile.isDefender}');

    _setLoading(true);
    _clearError();

    try {
      final success = await _profileService.createProfile(_profile, token);
      
      if (success) {
        await _profileService.saveProfileLocally(_profile);
        return true;
      } else {
        _setError('Error al guardar el perfil. Intenta nuevamente.');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión. Verifica tu internet.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProfile(String token) async {
    _setLoading(true);
    _clearError();

    try {
      final profile = await _profileService.getProfile(token);
      if (profile != null) {
        _profile = profile;
        notifyListeners();
      }
    } catch (e) {
      _setError('Error al cargar el perfil');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}