import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/profile.dart';
import '../providers/auth.dart';
import '../providers/phone_input.dart' as phone_input_provider;
import '../widgets/profile_form_widget.dart';

class ProfileScreen extends StatefulWidget {
  final bool fromVerification;
  
  const ProfileScreen({Key? key, this.fromVerification = false}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Si viene de la verificación, obtener timezone del PhoneInputProvider
      if (widget.fromVerification) {
        final phoneInputProvider = Provider.of<phone_input_provider.PhoneInputProvider>(context, listen: false);
        profileProvider.updateTimezone(phoneInputProvider.timezone);
      }
      
      // Cargar perfil del servidor si hay token
      if (authProvider.token != null) {
        profileProvider.loadProfile(authProvider.token!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.fromVerification ? null : AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Perfil',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            return ProfileFormWidget(
              title: 'Auto Percepción',
              subtitle: 'Define tu perfil de jugador',
              buttonText: 'Finalizar Perfil',
              name: profileProvider.profile.name,
              age: profileProvider.profile.age,
              isNameEditable: true,
              isAgeEditable: true,
              skills: profileProvider.profile.skills,
              averageSkills: profileProvider.profile.averageSkills,
              numberOfOpinions: profileProvider.profile.numberOfOpinions,
              photoUrl: profileProvider.profile.photoUrl,
              photoPath: profileProvider.profile.photoPath,
              isGoalkeeper: profileProvider.profile.isGoalkeeper,
              isStriker: profileProvider.profile.isStriker,
              isMidfielder: profileProvider.profile.isMidfielder,
              isDefender: profileProvider.profile.isDefender,
              showPositionCheckboxes: true,
              onNameChanged: (name) => profileProvider.updateName(name),
              onAgeChanged: (age) => profileProvider.updateAge(age),
              onSkillChanged: (skill, value) => profileProvider.updateSkill(skill, value),
              onGoalkeeperChanged: () => profileProvider.updateIsGoalkeeper(!profileProvider.profile.isGoalkeeper),
              onStrikerChanged: () => profileProvider.updateIsStriker(!profileProvider.profile.isStriker),
              onMidfielderChanged: () => profileProvider.updateIsMidfielder(!profileProvider.profile.isMidfielder),
              onDefenderChanged: () => profileProvider.updateIsDefender(!profileProvider.profile.isDefender),
              onPhotoPicked: () => _showImagePickerDialog(profileProvider),
              onButtonPressed: () => _finishProfile(profileProvider),
              isLoading: profileProvider.isLoading,
              error: profileProvider.error,
              canSave: profileProvider.canSaveProfile,
            );
          },
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
              subtitle: kIsWeb ? const Text('Seleccionar archivo desde el dispositivo') : null,
              onTap: () {
                Navigator.pop(context);
                profileProvider.pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Cámara'),
              subtitle: kIsWeb 
                ? const Text('Puede requerir permisos del navegador')
                : const Text('Tomar foto con la cámara'),
              onTap: () {
                Navigator.pop(context);
                profileProvider.pickImage(ImageSource.camera);
              },
            ),
            if (kIsWeb)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Nota: En navegadores web, la cámara puede requerir permisos adicionales. Si no funciona, usa la opción de galería.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
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