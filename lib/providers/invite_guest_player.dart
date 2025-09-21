import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/network.dart';
import '../services/invite_guest_player.dart';
import 'auth.dart' as auth_provider;
import 'profile.dart' as profile_provider;
import 'invitations.dart';

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
  bool _isGoalkeeper = false;
  bool _isStriker = false;
  bool _isMidfielder = false;
  bool _isDefender = false;
  bool _isLoading = false;
  String? _error;

  // Inicializar nombre con "amige de [nombre del usuario]"
  void initializeName(BuildContext context) {
    final profileProvider = Provider.of<profile_provider.ProfileProvider>(context, listen: false);
    final userName = profileProvider.profile.name.isNotEmpty 
        ? profileProvider.profile.name 
        : 'Usuario';
    _nameController.text = 'amige de $userName';
    notifyListeners();
  }

  // Getters
  GlobalKey<FormState> get formKey => _formKey;
  TextEditingController get nameController => _nameController;
  int get selectedAge => _selectedAge;
  Map<String, double> get skills => Map.unmodifiable(_skills);
  bool get isGoalkeeper => _isGoalkeeper;
  bool get isStriker => _isStriker;
  bool get isMidfielder => _isMidfielder;
  bool get isDefender => _isDefender;
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

  void updateIsGoalkeeper(bool value) {
    _isGoalkeeper = value;
    notifyListeners();
  }

  void updateIsStriker(bool value) {
    _isStriker = value;
    notifyListeners();
  }

  void updateIsMidfielder(bool value) {
    _isMidfielder = value;
    notifyListeners();
  }

  void updateIsDefender(bool value) {
    _isDefender = value;
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
  Future<bool> inviteGuestPlayer(BuildContext context, Fulbito fulbito) async {
    if (!validateForm()) return false;

    _setLoading(true);
    _clearError();

    try {
      final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
      if (authProvider.token == null) {
        _setError('No hay token de autenticación');
        return false;
      }

      print('🔍 [InviteGuestPlayerProvider] Invitando jugador invitado:');
      print('🔍 Fulbito ID: ${fulbito.id}');
      print('🔍 Nombre: ${_nameController.text}');
      print('🔍 Edad: $_selectedAge');
      print('🔍 Habilidades: $_skills');

      final response = await InviteGuestPlayerService.inviteGuestPlayer(
        token: authProvider.token!,
        fulbitoId: fulbito.id,
        guestName: _nameController.text,
        skills: _skills,
      );

      if (response['success']) {
        // Mostrar modal de éxito
        if (context.mounted) {
          _showInvitationSuccessModal(context, response['data']);
          
          // Recargar datos para actualizar el estado
          final invitationsProvider = Provider.of<InvitationsProvider>(context, listen: false);
          invitationsProvider.load(authProvider.token!);
        }
        
        _setLoading(false);
        return true;
      } else {
        // Mostrar modal de error
        if (context.mounted) {
          _showInvitationErrorModal(context, response['message'] ?? 'Error al invitar jugador');
        }
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error invitando jugador invitado: $e');
      return false;
    } finally {
      _setLoading(false);
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
    _isGoalkeeper = false;
    _isStriker = false;
    _isMidfielder = false;
    _isDefender = false;
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

  // Métodos para mostrar modales
  void _showInvitationSuccessModal(BuildContext context, dynamic data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¡Invitación Exitosa!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Has invitado exitosamente al jugador al fulbito.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green[600], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El jugador invitado aparecerá en la lista de participantes del fulbito.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Cerrar también la pantalla de invitación
              },
              child: Text(
                'Continuar',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showInvitationErrorModal(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error en la Invitación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No se pudo completar la invitación.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Reintentar',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
