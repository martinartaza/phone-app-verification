import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FulbitoFormWidget extends StatefulWidget {
  final String? initialName;
  final String? initialPlace;
  final String? initialDay;
  final String? initialHour;
  final String? initialRegistrationDay;
  final String? initialRegistrationHour;
  final String? initialInvitationGuestStartDay;
  final String? initialInvitationGuestStartHour;
  final int? initialCapacity;
  final bool isEditMode;
  final bool showSaveButton;
  final String saveButtonText;
  final Function(String name, String place, String day, String hour, String registrationDay, String registrationHour, String? invitationGuestStartDay, String? invitationGuestStartHour, int capacity)? onSave;

  const FulbitoFormWidget({
    Key? key,
    this.initialName,
    this.initialPlace,
    this.initialDay,
    this.initialHour,
    this.initialRegistrationDay,
    this.initialRegistrationHour,
    this.initialInvitationGuestStartDay,
    this.initialInvitationGuestStartHour,
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
  late TextEditingController _hourController;
  late TextEditingController _registrationHourController;
  late TextEditingController _invitationHourController;
  
  late String _selectedDay;
  late String _selectedHour;
  late String _selectedRegistrationDay;
  late String _selectedRegistrationHour;
  
  // Variables para invitaciones de invitados
  bool _invitationsEnabled = false;
  late String _selectedInvitationGuestStartDay;
  late String _selectedInvitationGuestStartHour;


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

  // Validación de hora HH:MM (00-23):(00-59)
  final RegExp _hhmmRegex = RegExp(r'^(?:[01][0-9]|2[0-3]):[0-5][0-9]$');

  // Helper: normaliza un string de día (puede venir en español o inglés)
  String _normalizeDay(String? input) {
    if (input == null || input.trim().isEmpty) return 'saturday';
    final raw = input.trim().toLowerCase();

    // Mapa rápido label->value (sin acentos)
    String stripAccents(String s) => s
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');

    final labelToValue = {
      stripAccents('lunes'): 'monday',
      stripAccents('martes'): 'tuesday',
      stripAccents('miercoles'): 'wednesday',
      stripAccents('miércoles'): 'wednesday',
      stripAccents('jueves'): 'thursday',
      stripAccents('viernes'): 'friday',
      stripAccents('sabado'): 'saturday',
      stripAccents('sábado'): 'saturday',
      stripAccents('domingo'): 'sunday',
    };

    final normalized = stripAccents(raw);

    // Si ya es un value válido, devolverlo
    final validValues = _days.map((d) => d['value']).whereType<String>().toSet();
    if (validValues.contains(normalized)) return normalized;

    // Si coincide con algún label español, mapear
    if (labelToValue.containsKey(normalized)) {
      return labelToValue[normalized]!;
    }

    // Fallback
    return 'saturday';
  }

  // Helper: normaliza entradas a formato HH:MM
  String _normalizeHour(String input) {
    String t = input.trim();
    if (t.isEmpty) return '';

    // Reemplazar punto o coma por dos puntos
    t = t.replaceAll('.', ':').replaceAll(',', ':');

    // Si viene con segundos, cortar
    if (RegExp(r'^\d{1,2}:\d{2}:\d{2}').hasMatch(t)) {
      t = t.split(':').sublist(0, 2).join(':');
    }

    // Caso HH:MM parcial
    if (RegExp(r'^\d{1,2}:\d{0,2}').hasMatch(t)) {
      final parts = t.split(':');
      int hh = int.tryParse(parts[0]) ?? 0;
      String mm = parts.length > 1 ? parts[1] : '';
      if (mm.length == 1) mm = '0$mm';
      if (mm.isEmpty) mm = '00';
      if (hh < 0) hh = 0; if (hh > 23) hh = 23;
      int mmi = int.tryParse(mm) ?? 0; if (mmi > 59) mmi = 59;
      final hhStr = hh.toString().padLeft(2, '0');
      final mmStr = mmi.toString().padLeft(2, '0');
      return '$hhStr:$mmStr';
    }

    // Caso solo dígitos: 900 -> 09:00, 21 -> 21:00, 2130 -> 21:30
    if (RegExp(r'^\d{1,4}').hasMatch(t)) {
      final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length <= 2) {
        final hh = int.parse(digits);
        final hhStr = hh.clamp(0, 23).toString().padLeft(2, '0');
        return '$hhStr:00';
      }
      final hh = int.parse(digits.substring(0, digits.length - 2)).clamp(0, 23);
      final mm = int.parse(digits.substring(digits.length - 2)).clamp(0, 59);
      final hhStr = hh.toString().padLeft(2, '0');
      final mmStr = mm.toString().padLeft(2, '0');
      return '$hhStr:$mmStr';
    }

    // Fallback: intentar extraer HH:MM
    final match = RegExp(r'(\d{1,2})[:h]?(\d{2})').firstMatch(t);
    if (match != null) {
      final hh = int.parse(match.group(1)! ).clamp(0, 23);
      final mm = int.parse(match.group(2)! ).clamp(0, 59);
      return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
    }

    return '';
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _placeController = TextEditingController(text: widget.initialPlace ?? '');
    _capacityController = TextEditingController(text: (widget.initialCapacity ?? 10).toString());
    _selectedDay = _normalizeDay(widget.initialDay ?? 'saturday');
    
    // Limpiar la hora para que coincida con el formato del dropdown (HH:MM)
    String initialHour = widget.initialHour ?? '12:00';
    if (initialHour.length > 5) {
      initialHour = initialHour.substring(0, 5);
    }
    initialHour = _normalizeHour(initialHour).isEmpty ? '12:00' : _normalizeHour(initialHour);
    _selectedHour = initialHour;
    _hourController = TextEditingController(text: _selectedHour);
    
    _selectedRegistrationDay = _normalizeDay(widget.initialRegistrationDay ?? 'monday');
    
    // Limpiar la hora de registro para que coincida con el formato del dropdown (HH:MM)
    String initialRegistrationHour = widget.initialRegistrationHour ?? '12:00';
    if (initialRegistrationHour.length > 5) {
      initialRegistrationHour = initialRegistrationHour.substring(0, 5);
    }
    initialRegistrationHour = _normalizeHour(initialRegistrationHour).isEmpty ? '12:00' : _normalizeHour(initialRegistrationHour);
    _selectedRegistrationHour = initialRegistrationHour;
    _registrationHourController = TextEditingController(text: _selectedRegistrationHour);
    
    // Inicializar campos de invitaciones de invitados
    _invitationsEnabled = widget.initialInvitationGuestStartDay != null && widget.initialInvitationGuestStartHour != null;
    _selectedInvitationGuestStartDay = _normalizeDay(widget.initialInvitationGuestStartDay ?? 'monday');
    
    String initialInvitationGuestStartHour = widget.initialInvitationGuestStartHour ?? '12:00';
    if (initialInvitationGuestStartHour.length > 5) {
      initialInvitationGuestStartHour = initialInvitationGuestStartHour.substring(0, 5);
    }
    initialInvitationGuestStartHour = _normalizeHour(initialInvitationGuestStartHour).isEmpty ? '12:00' : _normalizeHour(initialInvitationGuestStartHour);
    _selectedInvitationGuestStartHour = initialInvitationGuestStartHour;
    _invitationHourController = TextEditingController(text: _selectedInvitationGuestStartHour);
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
                child: _buildTimeInput(
                  controller: _hourController,
                  onChanged: (value) => setState(() => _selectedHour = value),
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
                child: _buildTimeInput(
                  controller: _registrationHourController,
                  onChanged: (value) => setState(() => _selectedRegistrationHour = value),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Sección de habilitar invitados
          _buildInvitationsSection(),
          
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
    // Obsoleto: mantenido para compatibilidad si alguna ruta antigua lo usa.
    return const SizedBox.shrink();
  }

  Widget _buildTimeInput({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: '12:00',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF8B5CF6), width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      keyboardType: TextInputType.datetime,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}:?\d{0,2}$')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          final text = newValue.text;
          if (text.length == 2) {
            return TextEditingValue(
              text: '$text:',
              selection: newValue.selection,
            );
          }
          return newValue;
        }),
      ],
      validator: (value) {
        final text = (value ?? '').trim();
        if (text.isEmpty) return 'Ingrese una hora';
        if (!_hhmmRegex.hasMatch(text)) return 'Formato HH:MM (00-23):(00-59)';
        return null;
      },
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

  Widget _buildInvitationsSection() {
    return Column(
      children: [
        // Línea divisoria con texto centrado
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: Colors.grey.shade300,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _invitationsEnabled = !_invitationsEnabled;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: _invitationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _invitationsEnabled = value;
                        });
                      },
                      activeColor: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Habilitar Invitados',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.grey.shade300,
              ),
            ),
          ],
        ),
        
        // Campos de invitaciones (solo se muestran si está habilitado)
        if (_invitationsEnabled) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Inicio de inscripciones de invitados'),
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
                  value: _selectedInvitationGuestStartDay,
                  items: _days,
                  onChanged: (value) => setState(() => _selectedInvitationGuestStartDay = value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeInput(
                  controller: _invitationHourController,
                  onChanged: (value) => setState(() => _selectedInvitationGuestStartHour = value),
                ),
              ),
            ],
          ),
        ],
      ],
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
          _hourController.text.trim(),
          _selectedRegistrationDay,
          _registrationHourController.text.trim(),
          _invitationsEnabled ? _selectedInvitationGuestStartDay : null,
          _invitationsEnabled ? _invitationHourController.text.trim() : null,
          capacity,
        );
      }
    }
  }
}
