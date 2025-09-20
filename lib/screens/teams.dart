import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/teams.dart';
import '../widgets/dual_hexagon_chart.dart';

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
      
      print('🚀 TeamsScreen initState - Jugadores recibidos: ${widget.registeredPlayers.length}');
      for (var player in widget.registeredPlayers) {
        print('👤 Jugador completo: $player');
      }
      
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
                // Hexágono de comparación de equipos
                _buildTeamsComparisonHexagon(teamsProvider),
                
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

  Widget _buildTeamsComparisonHexagon(TeamsProvider teamsProvider) {
    return Container(
      width: 280,
      height: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Comparación de Equipos',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            
            // Hexágono dual
            Expanded(
              child: teamsProvider.hasTeamsData
                  ? Builder(
                      builder: (context) {
                        print('🎨 DualHexagonChart - Team1 skills: ${teamsProvider.team1AverageSkills}');
                        print('🎨 DualHexagonChart - Team2 skills: ${teamsProvider.team2AverageSkills}');
                        print('🎨 DualHexagonChart - Team1 count: ${teamsProvider.team1Count}');
                        print('🎨 DualHexagonChart - Team2 count: ${teamsProvider.team2Count}');
                        
                        return DualHexagonChart(
                          selfPerceptionSkills: teamsProvider.team1AverageSkills,
                          averageOpinionSkills: teamsProvider.team2AverageSkills,
                          numberOfOpinions: teamsProvider.team1Count + teamsProvider.team2Count,
                          size: 220,
                        );
                      },
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hexagon_outlined,
                            size: 60,
                            color: Color(0xFF9CA3AF),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Asigna jugadores para ver la comparación',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
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
    final team = player['team'];
    final backgroundColor = _getBackgroundColor(team);
    final alignment = _getContentAlignment(team);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: teamsProvider.getPlayerBorderColor(team),
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
          
          // Contenido central (foto y nombre)
          Expanded(
            child: Align(
              alignment: alignment,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Foto del usuario
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: teamsProvider.getPlayerBorderColor(team),
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildPlayerPhoto(player, teamsProvider),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Nombre del jugador
                  Text(
                    player['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: teamsProvider.getPlayerTextColor(team),
                    ),
                    textAlign: _getTextAlign(team),
                  ),
                ],
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

  Color _getBackgroundColor(int team) {
    switch (team) {
      case 1:
        return const Color(0xFFE0F2FE); // Celeste claro para Team 1
      case 2:
        return const Color(0xFFFEE2E2); // Rojo claro para Team 2
      default:
        return Colors.white; // Blanco para no asignado
    }
  }

  Alignment _getContentAlignment(int team) {
    switch (team) {
      case 1:
        return Alignment.centerLeft; // Alineado a la izquierda para Team 1
      case 2:
        return Alignment.centerRight; // Alineado a la derecha para Team 2
      default:
        return Alignment.center; // Centrado para no asignado
    }
  }

  TextAlign _getTextAlign(int team) {
    switch (team) {
      case 1:
        return TextAlign.left; // Texto alineado a la izquierda para Team 1
      case 2:
        return TextAlign.right; // Texto alineado a la derecha para Team 2
      default:
        return TextAlign.center; // Texto centrado para no asignado
    }
  }
}
