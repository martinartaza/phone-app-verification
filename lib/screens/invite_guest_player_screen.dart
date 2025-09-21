import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/network.dart';
import '../widgets/profile_form_widget.dart';
import '../providers/invite_guest_player.dart';

class InviteGuestPlayerScreen extends StatefulWidget {
  final Fulbito fulbito;

  const InviteGuestPlayerScreen({Key? key, required this.fulbito}) : super(key: key);

  @override
  State<InviteGuestPlayerScreen> createState() => _InviteGuestPlayerScreenState();
}

class _InviteGuestPlayerScreenState extends State<InviteGuestPlayerScreen> {
  @override
  void dispose() {
    // Limpiar el estado del provider cuando se cierre la pantalla
    final inviteProvider = Provider.of<InviteGuestPlayerProvider>(context, listen: false);
    inviteProvider.clearState();
    super.dispose();
  }

  Future<void> _inviteGuestPlayer() async {
    final inviteProvider = Provider.of<InviteGuestPlayerProvider>(context, listen: false);
    
    final success = await inviteProvider.inviteGuestPlayer(widget.fulbito);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jugador invitado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(inviteProvider.error ?? 'Error al invitar jugador'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: inviteProvider.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del fulbito
                    Container(
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
                    
                    const SizedBox(height: 24),
                    
                    // Formulario del jugador invitado
                    ProfileFormWidget(
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
                      onNameChanged: (value) => inviteProvider.nameController.text = value,
                      onAgeChanged: (value) => inviteProvider.updateAge(value),
                      onSkillChanged: (skillName, value) => inviteProvider.updateSkill(skillName, value),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Botón de invitar jugador
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: inviteProvider.isLoading ? null : _inviteGuestPlayer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: inviteProvider.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Invitar Jugador',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
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
