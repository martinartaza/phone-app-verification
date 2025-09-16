import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/network.dart';
import '../widgets/profile_form_widget.dart';
import '../services/vote.dart';
import '../providers/auth.dart' as auth_provider;

class VotePlayerScreen extends StatefulWidget {
  final NetworkUser player;

  const VotePlayerScreen({Key? key, required this.player}) : super(key: key);

  @override
  State<VotePlayerScreen> createState() => _VotePlayerScreenState();
}

class _VotePlayerScreenState extends State<VotePlayerScreen> {
  final VoteService _voteService = VoteService();
  
  // Votación del usuario (empieza en 50 para todas las habilidades)
  Map<String, double> _userVote = {
    'velocidad': 50.0,
    'resistencia': 50.0,
    'tiro': 50.0,
    'gambeta': 50.0,
    'pases': 50.0,
    'defensa': 50.0,
  };

  // Promedio del jugador (simulado por ahora, vendrá de la API)
  Map<String, double> _playerAverage = {
    'velocidad': 75.0,
    'resistencia': 10.0,
    'tiro': 60.0,
    'gambeta': 45.0,
    'pases': 30.0,
    'defensa': 20.0,
  };

  bool _isLoading = false;
  String? _error;

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
        child: ProfileFormWidget(
          title: 'Te doy mi opinión',
          subtitle: 'Evalúa las habilidades de ${widget.player.username}',
          buttonText: 'Votación',
          name: widget.player.username,
          age: 30, // TODO: obtener edad del jugador desde la API
          isNameEditable: false,
          isAgeEditable: false,
          skills: _userVote, // La votación del usuario (azul en el hexágono)
          averageSkills: _playerAverage, // El promedio del jugador (rojo en el hexágono)
          numberOfOpinions: 5, // TODO: obtener desde la API
          photoUrl: widget.player.photoUrl,
          photoPath: null,
          isGoalkeeper: false, // TODO: obtener desde la API
          isStriker: false, // TODO: obtener desde la API
          isMidfielder: false, // TODO: obtener desde la API
          isDefender: false, // TODO: obtener desde la API
          showPositionCheckboxes: false, // No mostrar checkboxes en votación
          onNameChanged: null, // No editable
          onAgeChanged: null, // No editable
          onSkillChanged: (skill, value) {
            setState(() {
              _userVote[skill] = value;
            });
          },
          onGoalkeeperChanged: null, // No mostrar
          onStrikerChanged: null, // No mostrar
          onMidfielderChanged: null, // No mostrar
          onDefenderChanged: null, // No mostrar
          onPhotoPicked: null, // No editable
          onButtonPressed: _submitVote,
          isLoading: _isLoading,
          error: _error,
          canSave: true,
        ),
      ),
    );
  }

  Future<void> _submitVote() async {
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

      final success = await _voteService.submitVote(
        token, 
        widget.player.uuid, 
        _userVote
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Mostrar mensaje de éxito y volver al home
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Votación enviada para ${widget.player.username}'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context);
        } else {
          setState(() {
            _error = 'Error al enviar la votación. Intenta nuevamente.';
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
