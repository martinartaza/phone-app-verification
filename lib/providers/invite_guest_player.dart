import 'package:flutter/material.dart';
import '../models/network.dart';

class InviteGuestPlayerProvider extends ChangeNotifier {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _selectedAge = 30;
  final Map<String, double> _skills = {
    'velocidad': 50.0,
    'resistencia': 50.0,
    'tiro_arco': 50.0,
    'gambeta': 50.0,
    'pases': 50.0,
    'defensa': 50.0,
  };
  bool _isLoading = false;
  String? _error;

  // Getters
  GlobalKey<FormState> get formKey => _formKey;
  TextEditingController get nameController => _nameController;
  int get selectedAge => _selectedAge;
  Map<String, double> get skills => Map.unmodifiable(_skills);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Setters
  void updateAge(int age) {
    _selectedAge = age;
    notifyListeners();
  }

  void updateSkill(String skillName, double value) {
    _skills[skillName] = value;
    notifyListeners();
  }

  void updateSkills(Map<String, double> newSkills) {
    _skills.clear();
    _skills.addAll(newSkills);
    notifyListeners();
  }

  // Validación del formulario
  bool validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    
    if (_nameController.text.trim().isEmpty) {
      _setError('El nombre es requerido');
      return false;
    }
    
    return true;
  }

  // Invitar jugador invitado
  Future<bool> inviteGuestPlayer(Fulbito fulbito) async {
    if (!validateForm()) return false;

    _setLoading(true);
    _clearError();

    try {
      // TODO: Implementar llamada a la API para invitar jugador invitado
      await Future.delayed(const Duration(seconds: 2)); // Simulación
      
      // Simular éxito
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al invitar jugador: $e');
      _setLoading(false);
      return false;
    }
  }

  // Limpiar estado
  void clearState() {
    _nameController.clear();
    _selectedAge = 30;
    _skills.clear();
    _skills.addAll({
      'velocidad': 50.0,
      'resistencia': 50.0,
      'tiro_arco': 50.0,
      'gambeta': 50.0,
      'pases': 50.0,
      'defensa': 50.0,
    });
    _isLoading = false;
    _clearError();
    notifyListeners();
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
