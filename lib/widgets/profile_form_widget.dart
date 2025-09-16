import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../widgets/dual_hexagon_chart.dart';

typedef SkillChangedCallback = void Function(String skill, double value);

class ProfileFormWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final String name;
  final int age;
  final bool isNameEditable;
  final bool isAgeEditable;
  final Map<String, double> skills;
  final Map<String, double> averageSkills;
  final int numberOfOpinions;
  final String? photoUrl;
  final String? photoPath;
  final bool isGoalkeeper;
  final bool isStriker;
  final bool isMidfielder;
  final bool isDefender;
  final bool showPositionCheckboxes;
  final ValueChanged<String>? onNameChanged;
  final ValueChanged<int>? onAgeChanged;
  final SkillChangedCallback? onSkillChanged;
  final VoidCallback? onGoalkeeperChanged;
  final VoidCallback? onStrikerChanged;
  final VoidCallback? onMidfielderChanged;
  final VoidCallback? onDefenderChanged;
  final VoidCallback? onPhotoPicked;
  final VoidCallback? onButtonPressed;
  final bool isLoading;
  final String? error;
  final bool canSave;

  const ProfileFormWidget({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.name,
    required this.age,
    this.isNameEditable = true,
    this.isAgeEditable = true,
    required this.skills,
    required this.averageSkills,
    required this.numberOfOpinions,
    this.photoUrl,
    this.photoPath,
    this.isGoalkeeper = false,
    this.isStriker = false,
    this.isMidfielder = false,
    this.isDefender = false,
    this.showPositionCheckboxes = true,
    this.onNameChanged,
    this.onAgeChanged,
    this.onSkillChanged,
    this.onGoalkeeperChanged,
    this.onStrikerChanged,
    this.onMidfielderChanged,
    this.onDefenderChanged,
    this.onPhotoPicked,
    this.onButtonPressed,
    this.isLoading = false,
    this.error,
    this.canSave = true,
  }) : super(key: key);

  @override
  State<ProfileFormWidget> createState() => _ProfileFormWidgetState();
}

class _ProfileFormWidgetState extends State<ProfileFormWidget> {
  final _nameController = TextEditingController();
  int _selectedAge = 30;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
    _selectedAge = widget.age;
  }

  @override
  void didUpdateWidget(ProfileFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      _nameController.text = widget.name;
    }
    if (oldWidget.age != widget.age) {
      _selectedAge = widget.age;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 2),
          
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          
          const SizedBox(height: 6),
          
          Text(
            widget.subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Foto de perfil
          _buildProfilePhoto(),
          
          const SizedBox(height: 20),
          
          // Labels de Nombre y Edad
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Nombre',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Edad',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Inputs de Nombre y Edad
          Row(
            children: [
              Expanded(child: _buildNameInput()),
              const SizedBox(width: 16),
              Expanded(child: _buildAgeSelector()),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Hexágonos duales
          DualHexagonChart(
            selfPerceptionSkills: widget.skills,
            averageOpinionSkills: widget.averageSkills,
            numberOfOpinions: widget.numberOfOpinions,
            size: 200,
          ),
          
          const SizedBox(height: 20),
          
          // Sliders de habilidades
          _buildSkillSliders(),
          
          const SizedBox(height: 16),
          
          // Checkboxes de posiciones (solo si se muestran)
          if (widget.showPositionCheckboxes) _buildPositionCheckboxes(),
          
          const SizedBox(height: 24),
          
          // Error message
          if (widget.error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                widget.error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          
          // Botón
          _buildButton(),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return GestureDetector(
      onTap: widget.onPhotoPicked,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: _buildPhotoContent(),
      ),
    );
  }

  Widget _buildPhotoContent() {
    // Prioridad: foto local > foto del servidor > icono por defecto
    if (widget.photoPath != null) {
      // Foto local (recién seleccionada)
      return ClipOval(
        child: Image.file(
          File(widget.photoPath!),
          fit: BoxFit.cover,
        ),
      );
    } else if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty) {
      // Foto del servidor
      return ClipOval(
        child: Image.network(
          widget.photoUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: const Color(0xFF8B5CF6),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error loading profile photo: $error');
            return Icon(
              Icons.add_a_photo,
              size: 40,
              color: Colors.grey.shade600,
            );
          },
        ),
      );
    } else {
      // Icono por defecto
      return Icon(
        Icons.add_a_photo,
        size: 40,
        color: Colors.grey.shade600,
      );
    }
  }

  Widget _buildNameInput() {
    return TextField(
      controller: _nameController,
      enabled: widget.isNameEditable,
      onChanged: widget.isNameEditable ? (value) {
        widget.onNameChanged?.call(value);
      } : null,
      decoration: InputDecoration(
        hintText: 'Tu nombre',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: !widget.isNameEditable,
        fillColor: widget.isNameEditable ? null : Colors.grey.shade100,
      ),
    );
  }

  Widget _buildAgeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: widget.isAgeEditable ? null : Colors.grey.shade100,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedAge,
          hint: const Text('Tu edad'),
          isExpanded: true,
          isDense: true,
          items: List.generate(50, (index) => index + 16)
              .map((age) => DropdownMenuItem(
                    value: age,
                    child: Text(age.toString()),
                  ))
              .toList(),
          onChanged: widget.isAgeEditable ? (value) {
            if (value != null) {
              setState(() {
                _selectedAge = value;
              });
              widget.onAgeChanged?.call(value);
            }
          } : null,
        ),
      ),
    );
  }

  Widget _buildSkillSliders() {
    final skills = [
      {'key': 'velocidad', 'label': 'Velocidad', 'icon': Icons.flash_on},
      {'key': 'resistencia', 'label': 'Resistencia', 'icon': Icons.fitness_center},
      {'key': 'tiro', 'label': 'Tiro a arco', 'icon': Icons.sports_soccer},
      {'key': 'gambeta', 'label': 'Gambeta', 'icon': Icons.shuffle},
      {'key': 'pases', 'label': 'Pases', 'icon': Icons.swap_horiz},
      {'key': 'defensa', 'label': 'Defensa', 'icon': Icons.shield},
    ];

    return Column(
      children: skills.map((skill) {
        final skillKey = skill['key'] as String;
        final skillValue = widget.skills[skillKey] ?? 50.0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(
                skill['icon'] as IconData,
                color: const Color(0xFF8B5CF6),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  skill['label'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                skillValue.round().toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF8B5CF6),
                    inactiveTrackColor: Colors.grey.shade300,
                    thumbColor: const Color(0xFF8B5CF6),
                    overlayColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: skillValue,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (value) {
                      widget.onSkillChanged?.call(skillKey, value);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPositionCheckboxes() {
    return Column(
      children: [
        // Buen arquero
        Row(
          children: [
            Checkbox(
              value: widget.isGoalkeeper,
              onChanged: widget.onGoalkeeperChanged != null ? (value) {
                widget.onGoalkeeperChanged?.call();
              } : null,
              activeColor: const Color(0xFF8B5CF6),
            ),
            const Text(
              'Buen arquero',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        // Es delantero
        Row(
          children: [
            Checkbox(
              value: widget.isStriker,
              onChanged: widget.onStrikerChanged != null ? (value) {
                widget.onStrikerChanged?.call();
              } : null,
              activeColor: const Color(0xFF8B5CF6),
            ),
            const Text(
              'Es delantero',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        // Es mediocampista
        Row(
          children: [
            Checkbox(
              value: widget.isMidfielder,
              onChanged: widget.onMidfielderChanged != null ? (value) {
                widget.onMidfielderChanged?.call();
              } : null,
              activeColor: const Color(0xFF8B5CF6),
            ),
            const Text(
              'Es mediocampista',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        // Es defensor
        Row(
          children: [
            Checkbox(
              value: widget.isDefender,
              onChanged: widget.onDefenderChanged != null ? (value) {
                widget.onDefenderChanged?.call();
              } : null,
              activeColor: const Color(0xFF8B5CF6),
            ),
            const Text(
              'Es defensor',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: widget.isLoading || !widget.canSave
            ? null
            : () => widget.onButtonPressed?.call(),
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
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        widget.buttonText,
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
}
