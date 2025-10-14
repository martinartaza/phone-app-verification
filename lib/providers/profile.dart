import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

  /// Provee una ImageProvider priorizando foto local y luego la URL del servidor.
  /// Úsese en la UI para mantener el widget libre de lógica.
  ImageProvider<Object> get profileImageProvider {
    if (_profile.photoPath != null) {
      return FileImage(File(_profile.photoPath!));
    }
    if (_profile.photoUrl != null && _profile.photoUrl!.isNotEmpty) {
      return NetworkImage(_profile.photoUrl!);
    }
    // Fallback a un asset por defecto
    return const AssetImage('assets/icons/logo.png');
  }

  bool get isNameValid {
    final name = _profile.name.trim();
    return name.length >= 4 && name.length <= 30;
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

  void updateTimezone(String timezone) {
    _profile = _profile.copyWith(timezone: timezone);
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
      // En web, la cámara puede no estar disponible
      if (kIsWeb && source == ImageSource.camera) {
        print('📱 Web: Intentando acceder a la cámara...');
      }
      
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        _profile = _profile.copyWith(photoPath: image.path);
        notifyListeners();
        print('✅ Imagen seleccionada: ${image.path}');
      } else {
        print('❌ No se seleccionó ninguna imagen');
      }
    } catch (e) {
      String errorMessage = 'Error al seleccionar imagen: $e';
      
      // Mensajes más específicos para web
      if (kIsWeb) {
        if (e.toString().contains('camera')) {
          errorMessage = 'No se pudo acceder a la cámara. Intenta seleccionar desde galería.';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Permisos de cámara denegados. Verifica la configuración del navegador.';
        }
      }
      
      _setError(errorMessage);
      print('❌ Error al seleccionar imagen: $e');
    }
  }

  Future<bool> saveProfile(String token) async {
    if (!canSaveProfile) {
      _setError('El nombre debe tener entre 4 y 30 caracteres');
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