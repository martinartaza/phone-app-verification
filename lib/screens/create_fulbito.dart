import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart' as auth_provider;
import '../providers/invitations.dart';
import '../services/fulbito.dart';
import '../models/fulbito_creation.dart';
import '../widgets/fulbito/fulbito_form_widget.dart';

class CreateFulbitoScreen extends StatefulWidget {
  const CreateFulbitoScreen({Key? key}) : super(key: key);

  @override
  State<CreateFulbitoScreen> createState() => _CreateFulbitoScreenState();
}

class _CreateFulbitoScreenState extends State<CreateFulbitoScreen> {
  bool _isLoading = false;
  String? _error;

  final FulbitoService _fulbitoService = FulbitoService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Crear Fulbito',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Título
              const Text(
                'Organiza tu fulbito',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Crea un nuevo fulbito y compártelo con tu red',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Formulario reutilizable
              FulbitoFormWidget(
                showSaveButton: true,
                saveButtonText: 'Crear Fulbito',
                onSave: _createFulbito,
              ),
              
              const SizedBox(height: 24),
              
              // Error message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createFulbito(String name, String place, String day, String hour, String registrationDay, String registrationHour, String? invitationGuestStartDay, String? invitationGuestStartHour, int capacity) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null) {
        setState(() {
          _error = 'No hay token de autenticación';
          _isLoading = false;
        });
        return;
      }

      final fulbito = FulbitoCreation(
        name: name,
        place: place,
        day: day,
        hour: '${hour}:00',
        registrationStartDay: registrationDay,
        registrationStartHour: '${registrationHour}:00',
        invitationGuestStartDay: invitationGuestStartDay,
        invitationGuestStartHour: invitationGuestStartHour != null ? '${invitationGuestStartHour}:00' : null,
        capacity: capacity,
      );

      final success = await _fulbitoService.createFulbito(token, fulbito);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Recargar los datos de invitaciones para actualizar la vista
          final invitationsProvider = Provider.of<InvitationsProvider>(context, listen: false);
          await invitationsProvider.load(token);
          
          // Mostrar mensaje de éxito y volver al home
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fulbito creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context);
        } else {
          setState(() {
            _error = 'Error al crear el fulbito. Intenta nuevamente.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error de conexión. Verifica tu internet.';
        });
      }
    }
  }
}
