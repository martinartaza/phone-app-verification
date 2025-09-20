import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/teams.dart';

class TeamsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> registeredPlayers;
  
  const TeamsScreen({
    Key? key,
    required this.registeredPlayers,
  }) : super(key: key);

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  @override
  void initState() {
    super.initState();
    // Inicializar el provider con los jugadores registrados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);
      teamsProvider.initializeWithPlayers(widget.registeredPlayers);
    });
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
          'Arma los equipos',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<TeamsProvider>(
        builder: (context, teamsProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Hexágono vacío
                _buildEmptyHexagon(),
                
                const SizedBox(height: 24),
                
                // Leyenda de equipos
                _buildTeamsLegend(teamsProvider),
                
                const SizedBox(height: 32),
                
                // Lista de jugadores
                _buildPlayersList(teamsProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyHexagon() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hexagon_outlined,
              size: 80,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 16),
            Text(
              'Hexágono de comparación',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Se mostrará cuando se asignen jugadores',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsLegend(TeamsProvider teamsProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Team 1
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Team 1 (${teamsProvider.team1Count})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(width: 32),
        // Team 2
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Team 2 (${teamsProvider.team2Count})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayersList(TeamsProvider teamsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jugadores (${teamsProvider.unassignedCount} sin asignar)',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 16),
        ...teamsProvider.players.map((player) => _buildPlayerItem(player, teamsProvider)),
      ],
    );
  }

  Widget _buildPlayerItem(Map<String, dynamic> player, TeamsProvider teamsProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: teamsProvider.getPlayerBorderColor(player['team']),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Flecha azul hacia la izquierda (Team 1)
          GestureDetector(
            onTap: () => teamsProvider.moveToTeam1(player['id']),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Foto del usuario
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: teamsProvider.getPlayerBorderColor(player['team']),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildPlayerPhoto(player, teamsProvider),
          ),
          
          const SizedBox(width: 16),
          
          // Nombre del jugador
          Expanded(
            child: Text(
              player['name'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: teamsProvider.getPlayerTextColor(player['team']),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Flecha roja hacia la derecha (Team 2)
          GestureDetector(
            onTap: () => teamsProvider.moveToTeam2(player['id']),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerPhoto(Map<String, dynamic> player, TeamsProvider teamsProvider) {
    final photoUrl = teamsProvider.getFullPhotoUrl(player['photoUrl']);
    
    if (photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.person, color: Colors.grey),
          );
        },
      );
    } else {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.person, color: Colors.grey),
      );
    }
  }
}
