import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/network.dart';
import '../../models/player.dart';
import '../../widgets/fulbito/fulbito_form_widget.dart';
import '../../widgets/dual_hexagon_chart.dart';
import '../../providers/fulbito/fulbito_provider.dart';
import '../../providers/auth.dart' as auth_provider;
import '../../config/api_config.dart';

class FulbitoDetailsScreen extends StatefulWidget {
  final Fulbito fulbito;

  const FulbitoDetailsScreen({
    Key? key,
    required this.fulbito,
  }) : super(key: key);

  @override
  State<FulbitoDetailsScreen> createState() => _FulbitoDetailsScreenState();
}

class _FulbitoDetailsScreenState extends State<FulbitoDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Si es admin, tiene 3 tabs, sino 2
    final isAdmin = widget.fulbito.isOwner;
    _tabController = TabController(length: isAdmin ? 3 : 2, vsync: this);
    
    // Siempre empezar en el tab "Detalles" (índice 1 para admin, índice 0 para invitado)
    _tabController.index = isAdmin ? 1 : 0;
    
    // Cargar datos del fulbito
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
      final fulbitoProvider = Provider.of<FulbitoProvider>(context, listen: false);
      
      if (authProvider.token != null) {
        fulbitoProvider.loadFulbitoDetails(
          widget.fulbito, 
          authProvider.phoneNumber ?? '', 
          authProvider.token!
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          widget.fulbito.name,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8B5CF6),
          labelColor: const Color(0xFF8B5CF6),
          unselectedLabelColor: Colors.grey,
          tabs: widget.fulbito.isOwner
              ? const [
                  Tab(text: 'Modificación'),
                  Tab(text: 'Detalles'),
                  Tab(text: 'Inscribirse'),
                ]
              : const [
                  Tab(text: 'Detalles'),
                  Tab(text: 'Inscribirse'),
                ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: widget.fulbito.isOwner
            ? [
                _buildModificationTab(),
                _buildDetailsTab(),
                _buildInscriptionTab(),
              ]
            : [
                _buildDetailsTab(),
                _buildInscriptionTab(),
              ],
      ),
    );
  }

  Widget _buildModificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: FulbitoFormWidget(
        initialName: widget.fulbito.name,
        initialPlace: widget.fulbito.place,
        initialDay: widget.fulbito.day,
        initialHour: widget.fulbito.hour,
        initialRegistrationDay: widget.fulbito.registrationStartDay,
        initialRegistrationHour: widget.fulbito.registrationStartHour,
        initialCapacity: widget.fulbito.capacity,
        isEditMode: true,
        saveButtonText: 'Actualizar Fulbito',
        onSave: (name, place, day, hour, registrationDay, registrationHour, capacity) {
          // Mock: mostrar mensaje de actualización
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fulbito actualizado (mock)'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsTab() {
    return Consumer<FulbitoProvider>(
      builder: (context, fulbitoProvider, child) {
        if (fulbitoProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (fulbitoProvider.error != null) {
          return Center(
            child: Text(
              fulbitoProvider.error!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Detalles del fulbito
              _buildDetailRow('Lugar:', widget.fulbito.place),
              _buildDetailRow('Horario:', '${_formatDay(widget.fulbito.day)} - ${_formatTime(widget.fulbito.hour)}'),
              _buildDetailRow('Capacidad:', '${widget.fulbito.capacity} jugadores'),
              _buildDetailRow('Inscripción:', '${_formatDay(widget.fulbito.registrationStartDay)} ${_formatTime(widget.fulbito.registrationStartHour)}'),
              
              const SizedBox(height: 16),
              
              // Hexágono con datos reales
              if (fulbitoProvider.selectedPlayer != null) ...[
                Text(
                  'Habilidades de ${fulbitoProvider.selectedPlayer!.username}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 16),
                
                DualHexagonChart(
                  selfPerceptionSkills: fulbitoProvider.selectedPlayer!.averageSkills,
                  averageOpinionSkills: fulbitoProvider.selectedPlayer!.averageSkills,
                  numberOfOpinions: 1,
                  size: 200,
                ),
              ] else ...[
                const Text(
                  'Habilidades del Jugador',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Selecciona un jugador',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Lista de jugadores
              const Text(
                'Lista de jugadores',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 16),
              
              // Lista real de jugadores
              if (fulbitoProvider.players.isEmpty)
                const Text(
                  'No hay jugadores registrados',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                )
              else
                ...fulbitoProvider.players.map((player) => _buildPlayerItem(player)),
              
              // Espacio adicional al final para evitar overflow
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInscriptionTab() {
    return const Center(
      child: Text(
        'Pestaña Inscribirse\n(Contenido próximamente)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerItem(Player player) {
    return Consumer<FulbitoProvider>(
      builder: (context, fulbitoProvider, child) {
        final isSelected = fulbitoProvider.selectedPlayer?.id == player.id;
        final isAdmin = player.type == 'admin';
        
        return GestureDetector(
          onTap: () => fulbitoProvider.selectPlayer(player),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFF8B5CF6).withOpacity(0.2)
                  : const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF8B5CF6).withOpacity(0.3),
                width: isSelected ? 2 : 1,
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: player.photoUrl != null && player.photoUrl!.isNotEmpty
                      ? Image.network(
                          player.photoUrl!.startsWith('http') 
                              ? player.photoUrl! 
                              : '${ApiConfig.baseUrl}${player.photoUrl!}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, color: Colors.grey);
                          },
                        )
                      : const Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        player.phone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icono según el tipo de jugador
                      Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.person,
                        color: isAdmin ? const Color(0xFFEF4444) : const Color(0xFF8B5CF6),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      // Indicador de selección
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF8B5CF6),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
