import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/network.dart';
import '../widgets/profile_form_widget.dart';
import '../providers/auth.dart' as auth_provider;
import '../providers/vote.dart';

class VotePlayerScreen extends StatefulWidget {
  final NetworkUser player;

  const VotePlayerScreen({Key? key, required this.player}) : super(key: key);

  @override
  State<VotePlayerScreen> createState() => _VotePlayerScreenState();
}

class _VotePlayerScreenState extends State<VotePlayerScreen> {

  @override
  void initState() {
    super.initState();
    _loadPlayerDetails();
  }

  @override
  void dispose() {
    // Limpiar el estado del provider cuando se cierre la pantalla
    final voteProvider = Provider.of<VoteProvider>(context, listen: false);
    voteProvider.clearState();
    super.dispose();
  }

  Future<void> _loadPlayerDetails() async {
    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final voteProvider = Provider.of<VoteProvider>(context, listen: false);
    
    if (authProvider.token != null) {
      await voteProvider.loadPlayerDetails(authProvider.token!, widget.player.uuid);
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
        title: Text(
          widget.player.username,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<VoteProvider>(
          builder: (context, voteProvider, child) {
            if (voteProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (voteProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      voteProvider.error!,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadPlayerDetails,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            
            if (voteProvider.playerDetails == null) {
              return const Center(child: Text('No se pudieron cargar los datos del jugador'));
            }
            
            final playerDetails = voteProvider.playerDetails!;
            return ProfileFormWidget(
              title: 'Te doy mi opinión',
              subtitle: 'Evalúa las habilidades de ${playerDetails.firstName}',
              buttonText: 'Votación',
              name: playerDetails.firstName,
              age: playerDetails.age,
              isNameEditable: false,
              isAgeEditable: false,
              skills: voteProvider.userVote, // La votación del usuario (azul en el hexágono)
              averageSkills: playerDetails.averageOpinion, // El promedio del jugador (rojo en el hexágono)
              numberOfOpinions: playerDetails.numberOfOpinions,
              photoUrl: playerDetails.photoUrl != null 
                  ? 'http://192.168.100.150:8000${playerDetails.photoUrl}' 
                  : null,
              photoPath: null,
              isGoalkeeper: playerDetails.isGoalkeeper,
              isStriker: playerDetails.isForward,
              isMidfielder: playerDetails.isMidfielder,
              isDefender: playerDetails.isDefender,
              showPositionCheckboxes: false, // No mostrar checkboxes en votación
              onNameChanged: null, // No editable
              onAgeChanged: null, // No editable
              onSkillChanged: (skill, value) {
                voteProvider.updateVote(skill, value);
              },
              onGoalkeeperChanged: null, // No mostrar
              onStrikerChanged: null, // No mostrar
              onMidfielderChanged: null, // No mostrar
              onDefenderChanged: null, // No mostrar
              onPhotoPicked: null, // No editable
              onButtonPressed: _submitVote,
              isLoading: voteProvider.isLoading,
              error: voteProvider.error,
              canSave: true,
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitVote() async {
    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final voteProvider = Provider.of<VoteProvider>(context, listen: false);
    
    if (authProvider.token == null) return;

    final success = await voteProvider.submitVote(authProvider.token!, widget.player.uuid);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Votación enviada para ${widget.player.username}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}
