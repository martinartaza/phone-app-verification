import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/profile.dart';
import '../providers/auth.dart';
import '../widgets/pentagon_chart.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  int _selectedAge = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      _nameController.text = profileProvider.profile.name;
      _selectedAge = profileProvider.profile.age;
      
      // Debug: Verificar valores
      print('🔍 ProfileScreen initState:');
      print('  - profile.name: ${profileProvider.profile.name}');
      print('  - profile.age: ${profileProvider.profile.age}');
      print('  - _selectedAge: $_selectedAge');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Actualizar la edad cuando el perfil cambie
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    if (_selectedAge != profileProvider.profile.age) {
      print('🔄 ProfileScreen didChangeDependencies:');
      print('  - _selectedAge: $_selectedAge');
      print('  - profile.age: ${profileProvider.profile.age}');
      setState(() {
        _selectedAge = profileProvider.profile.age;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 2),
                  
                  const Text(
                    'Auto Percepción',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  const Text(
                    'Define tu perfil de jugador',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Foto de perfil
                  _buildProfilePhoto(profileProvider),
                  
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
                      Expanded(child: _buildNameInput(profileProvider)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildAgeSelector(profileProvider)),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Pentágono
                  PentagonChart(
                    skills: profileProvider.profile.skills,
                    size: 200,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Sliders de habilidades
                  _buildSkillSliders(profileProvider),
                  
                  const SizedBox(height: 16),
                  
                  // Checkboxes de posiciones
                  _buildPositionCheckboxes(profileProvider),
                  
                  const SizedBox(height: 24),
                  
                  // Error message
                  if (profileProvider.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        profileProvider.error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  
                  // Botón Finalizar Perfil
                  _buildFinishButton(profileProvider),
                  
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfilePhoto(ProfileProvider profileProvider) {
    return GestureDetector(
      onTap: () => _showImagePickerDialog(profileProvider),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: profileProvider.profile.photoPath != null
            ? ClipOval(
                child: Image.file(
                  File(profileProvider.profile.photoPath!),
                  fit: BoxFit.cover,
                ),
              )
            : Icon(
                Icons.add_a_photo,
                size: 40,
                color: Colors.grey.shade600,
              ),
      ),
    );
  }

  Widget _buildNameInput(ProfileProvider profileProvider) {
    return TextField(
      controller: _nameController,
      onChanged: profileProvider.updateName,
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
        errorText: !profileProvider.isNameValid && _nameController.text.isNotEmpty
            ? 'Nombre de 4 a 20 caracteres'
            : null,
      ),
    );
  }

  Widget _buildAgeSelector(ProfileProvider profileProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedAge,
          hint: const Text('Tu edad'),
          isExpanded: true,
          items: List.generate(50, (index) => index + 16)
              .map((age) => DropdownMenuItem(
                    value: age,
                    child: Text(age.toString()),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedAge = value;
              });
              profileProvider.updateAge(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSkillSliders(ProfileProvider profileProvider) {
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
        final skillValue = profileProvider.profile.skills[skillKey] ?? 50.0;
        
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
                      profileProvider.updateSkill(skillKey, value);
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

  Widget _buildPositionCheckboxes(ProfileProvider profileProvider) {
    return Column(
      children: [
        // Buen arquero
        Row(
          children: [
            Checkbox(
              value: profileProvider.profile.isGoalkeeper,
              onChanged: (value) {
                profileProvider.updateIsGoalkeeper(value ?? false);
              },
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
              value: profileProvider.profile.isStriker,
              onChanged: (value) {
                profileProvider.updateIsStriker(value ?? false);
              },
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
              value: profileProvider.profile.isMidfielder,
              onChanged: (value) {
                profileProvider.updateIsMidfielder(value ?? false);
              },
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
              value: profileProvider.profile.isDefender,
              onChanged: (value) {
                profileProvider.updateIsDefender(value ?? false);
              },
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

  Widget _buildFinishButton(ProfileProvider profileProvider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: profileProvider.isLoading || !profileProvider.canSaveProfile
            ? null
            : () => _finishProfile(profileProvider),
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
            child: profileProvider.isLoading
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
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Finalizar Perfil',
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

  void _showImagePickerDialog(ProfileProvider profileProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                profileProvider.pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                profileProvider.pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finishProfile(ProfileProvider profileProvider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token != null) {
      final success = await profileProvider.saveProfile(token);
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }
}