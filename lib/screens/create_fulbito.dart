import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart' as auth_provider;
import '../providers/invitations.dart';
import '../services/fulbito.dart';
import '../models/fulbito_creation.dart';

class CreateFulbitoScreen extends StatefulWidget {
  const CreateFulbitoScreen({Key? key}) : super(key: key);

  @override
  State<CreateFulbitoScreen> createState() => _CreateFulbitoScreenState();
}

class _CreateFulbitoScreenState extends State<CreateFulbitoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _placeController = TextEditingController();
  
  String _selectedDay = 'saturday';
  String _selectedHour = '18:00';
  String _selectedRegistrationDay = 'monday';
  String _selectedRegistrationHour = '20:00';
  
  bool _isLoading = false;
  String? _error;

  final FulbitoService _fulbitoService = FulbitoService();

  final List<Map<String, String>> _days = [
    {'value': 'monday', 'label': 'Lunes'},
    {'value': 'tuesday', 'label': 'Martes'},
    {'value': 'wednesday', 'label': 'Miércoles'},
    {'value': 'thursday', 'label': 'Jueves'},
    {'value': 'friday', 'label': 'Viernes'},
    {'value': 'saturday', 'label': 'Sábado'},
    {'value': 'sunday', 'label': 'Domingo'},
  ];

  final List<String> _hours = [
    '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00',
    '16:00', '17:00', '18:00', '19:00', '20:00', '21:00', '22:00'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _placeController.dispose();
    super.dispose();
  }

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
          child: Form(
            key: _formKey,
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
                
                // Nombre del fulbito
                _buildSectionTitle('Nombre del fulbito'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameController,
                  hintText: 'Ej: Veteranos 50, Fútbol del Barrio',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    if (value.trim().length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Lugar
                _buildSectionTitle('Lugar'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _placeController,
                  hintText: 'Ej: Cancha San José, Polideportivo Municipal',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El lugar es obligatorio';
                    }
                    if (value.trim().length < 3) {
                      return 'El lugar debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Día y hora del fulbito
                _buildSectionTitle('Día y hora del fulbito'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        value: _selectedDay,
                        items: _days,
                        onChanged: (value) => setState(() => _selectedDay = value!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimeDropdown(
                        value: _selectedHour,
                        items: _hours,
                        onChanged: (value) => setState(() => _selectedHour = value!),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Día y hora de inicio de inscripciones
                _buildSectionTitle('Inicio de inscripciones'),
                const SizedBox(height: 8),
                const Text(
                  '¿Cuándo pueden empezar a inscribirse?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        value: _selectedRegistrationDay,
                        items: _days,
                        onChanged: (value) => setState(() => _selectedRegistrationDay = value!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimeDropdown(
                        value: _selectedRegistrationHour,
                        items: _hours,
                        onChanged: (value) => setState(() => _selectedRegistrationHour = value!),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
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
                
                // Botón crear
                _buildCreateButton(),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((item) => DropdownMenuItem(
            value: item['value'],
            child: Text(item['label']!),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTimeDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((hour) => DropdownMenuItem(
            value: hour,
            child: Text(hour),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createFulbito,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ).copyWith(
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            alignment: Alignment.center,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_soccer, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Crear Fulbito',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _createFulbito() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
        name: _nameController.text.trim(),
        place: _placeController.text.trim(),
        day: _selectedDay,
        hour: '$_selectedHour:00',
        registrationStartDay: _selectedRegistrationDay,
        registrationStartHour: '$_selectedRegistrationHour:00',
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
