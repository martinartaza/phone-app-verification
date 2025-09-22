import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/network.dart';
import '../widgets/profile_form_widget.dart';
import '../providers/invite_guest_player.dart';

class InviteGuestPlayerScreen extends StatefulWidget {
  final Fulbito fulbito;

  const InviteGuestPlayerScreen({super.key, required this.fulbito});

  @override
  State<InviteGuestPlayerScreen> createState() => _InviteGuestPlayerScreenState();
}

class _InviteGuestPlayerScreenState extends State<InviteGuestPlayerScreen> {
  @override
  void initState() {
    super.initState();
    // Inicializar el nombre con "amige de [username]" cuando se abra la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inviteProvider = Provider.of<InviteGuestPlayerProvider>(context, listen: false);
      inviteProvider.initializeName(context);
    });
  }

  @override
  void dispose() {
    // Limpiar el estado del provider cuando se cierre la pantalla
    final inviteProvider = Provider.of<InviteGuestPlayerProvider>(context, listen: false);
    inviteProvider.clearState();
    super.dispose();
  }

  Future<void> _inviteGuestPlayer() async {
    final inviteProvider = Provider.of<InviteGuestPlayerProvider>(context, listen: false);
    
    await inviteProvider.inviteGuestPlayer(context, widget.fulbito);
    
    // Los modales de éxito/error se manejan en el provider
    // No necesitamos mostrar SnackBars adicionales aquí
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
          'Invitar Jugador',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<InviteGuestPlayerProvider>(
          builder: (context, inviteProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Form(
                key: inviteProvider.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del fulbito
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Invitar jugador a:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.fulbito.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDay(widget.fulbito.day)} ${_formatTime(widget.fulbito.hour)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Formulario del jugador invitado
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: ProfileFormWidget(
                      title: 'Datos del Jugador Invitado',
                      subtitle: 'Completa la información del jugador que quieres invitar',
                      buttonText: 'Invitar Jugador',
                      name: inviteProvider.nameController.text,
                      age: inviteProvider.selectedAge,
                      isNameEditable: true,
                      isAgeEditable: true,
                      skills: inviteProvider.skills,
                      averageSkills: inviteProvider.skills, // Para invitados, usar las mismas habilidades
                      numberOfOpinions: 0,
                      photoUrl: null,
                      photoPath: null,
                      isGoalkeeper: inviteProvider.isGoalkeeper,
                      isStriker: inviteProvider.isStriker,
                      isMidfielder: inviteProvider.isMidfielder,
                      isDefender: inviteProvider.isDefender,
                      showPositionCheckboxes: true,
                      onNameChanged: (value) => inviteProvider.nameController.text = value,
                      onAgeChanged: (value) => inviteProvider.updateAge(value),
                      onSkillChanged: (skillName, value) => inviteProvider.updateSkill(skillName, value),
                      onGoalkeeperChanged: () => inviteProvider.updateIsGoalkeeper(!inviteProvider.isGoalkeeper),
                      onStrikerChanged: () => inviteProvider.updateIsStriker(!inviteProvider.isStriker),
                      onMidfielderChanged: () => inviteProvider.updateIsMidfielder(!inviteProvider.isMidfielder),
                      onDefenderChanged: () => inviteProvider.updateIsDefender(!inviteProvider.isDefender),
                      onButtonPressed: () => _inviteGuestPlayer(),
                    ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDay(String day) {
    switch (day.toLowerCase()) {
      case 'monday': return 'Lunes';
      case 'tuesday': return 'Martes';
      case 'wednesday': return 'Miércoles';
      case 'thursday': return 'Jueves';
      case 'friday': return 'Viernes';
      case 'saturday': return 'Sábado';
      case 'sunday': return 'Domingo';
      default: return day;
    }
  }

  String _formatTime(String time) {
    if (time.length > 5) {
      return time.substring(0, 5); // HH:MM
    }
    return time;
  }
}
