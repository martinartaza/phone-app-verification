import 'package:flutter/material.dart';

class FulbitoFormWidget extends StatefulWidget {
  final String? initialName;
  final String? initialPlace;
  final String? initialDay;
  final String? initialHour;
  final String? initialRegistrationDay;
  final String? initialRegistrationHour;
  final int? initialCapacity;
  final bool isEditMode;
  final bool showSaveButton;
  final String saveButtonText;
  final Function(String name, String place, String day, String hour, String registrationDay, String registrationHour, int capacity)? onSave;

  const FulbitoFormWidget({
    Key? key,
    this.initialName,
    this.initialPlace,
    this.initialDay,
    this.initialHour,
    this.initialRegistrationDay,
    this.initialRegistrationHour,
    this.initialCapacity,
    this.isEditMode = false,
    this.showSaveButton = false,
    this.saveButtonText = 'Guardar',
    this.onSave,
  }) : super(key: key);

  @override
  State<FulbitoFormWidget> createState() => _FulbitoFormWidgetState();
}

class _FulbitoFormWidgetState extends State<FulbitoFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _placeController;
  late TextEditingController _capacityController;
  
  late String _selectedDay;
  late String _selectedHour;
  late String _selectedRegistrationDay;
  late String _selectedRegistrationHour;

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
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _placeController = TextEditingController(text: widget.initialPlace ?? '');
    _capacityController = TextEditingController(text: (widget.initialCapacity ?? 10).toString());
    _selectedDay = widget.initialDay ?? 'saturday';
    
    // Limpiar la hora para que coincida con el formato del dropdown (HH:MM)
    String initialHour = widget.initialHour ?? '18:00';
    if (initialHour.length > 5) {
      initialHour = initialHour.substring(0, 5);
    }
    _selectedHour = initialHour;
    
    _selectedRegistrationDay = widget.initialRegistrationDay ?? 'monday';
    
    // Limpiar la hora de registro para que coincida con el formato del dropdown (HH:MM)
    String initialRegistrationHour = widget.initialRegistrationHour ?? '20:00';
    if (initialRegistrationHour.length > 5) {
      initialRegistrationHour = initialRegistrationHour.substring(0, 5);
    }
    _selectedRegistrationHour = initialRegistrationHour;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _placeController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          
          // Capacidad
          _buildSectionTitle('Capacidad'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _capacityController,
            hintText: 'Ej: 10',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La capacidad es obligatoria';
              }
              final capacity = int.tryParse(value.trim());
              if (capacity == null) {
                return 'La capacidad debe ser un número';
              }
              if (capacity < 2) {
                return 'La capacidad debe ser al menos 2';
              }
              if (capacity > 50) {
                return 'La capacidad no puede ser mayor a 50';
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
          
          // Botón guardar
          if (widget.showSaveButton || widget.isEditMode) _buildSaveButton(),
        ],
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveChanges,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  widget.saveButtonText,
                  style: const TextStyle(
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

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      if (widget.onSave != null) {
        final capacity = int.parse(_capacityController.text.trim());
        widget.onSave!(
          _nameController.text.trim(),
          _placeController.text.trim(),
          _selectedDay,
          _selectedHour,
          _selectedRegistrationDay,
          _selectedRegistrationHour,
          capacity,
        );
      }
    }
  }
}
