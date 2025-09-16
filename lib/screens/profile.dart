import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/profile.dart';
import '../providers/auth.dart';
import '../widgets/profile_form_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

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