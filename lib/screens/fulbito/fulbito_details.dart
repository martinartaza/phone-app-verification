import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/network.dart';
import '../../models/player.dart';
import '../../widgets/fulbito/fulbito_form_widget.dart';
import '../../widgets/dual_hexagon_chart.dart';
import '../../providers/fulbito/fulbito_provider.dart';
import '../../providers/fulbito/fulbito_inscription_provider.dart';
import '../../providers/registration.dart';
import '../../providers/auth.dart' as auth_provider;
import '../../config/api_config.dart';
import '../teams.dart';
import '../invite_guest_player_screen.dart';
import '../../providers/unregister_guest.dart';

class FulbitoDetailsScreen extends StatefulWidget {
  final Fulbito fulbito;

  const FulbitoDetailsScreen({
    Key? key,
    required this.fulbito,
  }) : super(key: key);

  @override
  State<FulbitoDetailsScreen> createState() => _FulbitoDetailsScreenState();
}

class _FulbitoDetailsScreenState extends State<FulbitoDetailsScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  int? _regCountdown; // segundos hasta abrir inscripción
  int? _invCountdown; // segundos hasta abrir invitaciones
  DateTime? _regDeadline;
  DateTime? _invDeadline;
  late final ValueNotifier<int> _ticker;
  bool _isRefreshingOnZero = false;
  // Ya no usamos selección de invitado; la cancelación va como acción por item

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Siempre 3 tabs: Modificación (solo admin), Detalles, Inscripción
    _tabController = TabController(length: 3, vsync: this);
    _ticker = ValueNotifier<int>(0);
    
    // Empezar en el tab "Detalles" (índice 1)
    _tabController.index = 1;
    
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
      final fulbitoProvider = Provider.of<FulbitoProvider>(context, listen: false);
      if (authProvider.token != null) {
        await fulbitoProvider.loadFulbitoDetails(
          widget.fulbito,
          authProvider.phoneNumber ?? '',
          authProvider.token!,
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
          tabs: [
            if (widget.fulbito.isOwner) const Tab(text: 'Modificación'),
            const Tab(text: 'Detalles'),
            Tab(text: _getInscriptionTabText()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (widget.fulbito.isOwner) _buildModificationTab(),
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
        onSave: (name, place, day, hour, registrationDay, registrationHour, invitationGuestStartDay, invitationGuestStartHour, capacity) {
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
                
                Center(
                  child: DualHexagonChart(
                    selfPerceptionSkills: fulbitoProvider.selectedPlayer!.averageSkills,
                    averageOpinionSkills: fulbitoProvider.selectedPlayer!.averageSkills,
                    numberOfOpinions: 1,
                    size: 200,
                  ),
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
                
                Center(
                  child: Container(
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
              const SizedBox(height: 16),

              // Botón para invitar jugadores
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/fulbito/invite-players');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_add, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Invitar jugadores',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  String _getInscriptionTabText() {
    if (widget.fulbito.registrationStatus == null) {
      return 'Inscribirse';
    }
    
    final status = widget.fulbito.registrationStatus!;
    if (status.nextMatchDate.isNotEmpty) {
      // Formatear la fecha para mostrar solo DD/MM
      try {
        final date = DateTime.parse(status.nextMatchDate);
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
      } catch (e) {
        return status.nextMatchDate;
      }
    }
    
    return 'Inscribirse';
  }

  Widget _buildInscriptionTab() {
    return Consumer<FulbitoProvider>(
      builder: (context, fulbitoProvider, child) {
        // Usar datos del FulbitoProvider en lugar del widget
        final fulbito = fulbitoProvider.currentFulbito ?? widget.fulbito;
        
        if (fulbito.registrationStatus == null) {
          return const Center(
            child: Text(
              'No hay información de inscripción disponible',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF6B7280),
              ),
            ),
          );
        }

        final status = fulbito.registrationStatus!;
        final isRegistrationOpen = status.registrationOpen;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado de inscripción
              _buildInscriptionStatusCard(status, isRegistrationOpen),
              
              const SizedBox(height: 24),
              
          // Contenido según el estado (simplificado)
          if (!isRegistrationOpen) ...[
            _buildRegistrationClosedContent(status),
          ] else ...[
            _buildRegistrationOpenContent(status),
          ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInscriptionStatusCard(RegistrationStatus status, bool isOpen) {
    _ensureTimersFromStatus(status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFF0FDF4) : const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOpen ? Icons.check_circle : Icons.schedule,
                color: isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isOpen ? 'Inscripción ABIERTA' : 'Inscripción CERRADA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Próximo partido: ${_formatNextMatch(status)}',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inscritos: ${status.registeredCount}/${status.capacity}',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          if (status.userPosition != null) ...[
            const SizedBox(height: 8),
            Text(
              'Tu posición: ${status.userPosition}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ],
          
          // Se oculta sección de invitaciones en la tarjeta superior
        ],
      ),
    );
  }

  Widget _buildRegistrationClosedContent(RegistrationStatus status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.schedule,
            size: 48,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(height: 16),
          const Text(
            'Inscripción CERRADA hasta:',
            style: TextStyle(fontSize: 16, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 8),
          Text(
            _formatOpensAt(status.opensAt),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationOpenContent(RegistrationStatus status) {
    return Column(
      children: [
        // Botón (Inscribirse o Desinscribirse) según si el usuario ya está registrado (player/substitute)
        Consumer<RegistrationProvider>(
          builder: (context, regProvider, child) {
            final authProv = Provider.of<auth_provider.AuthProvider>(context, listen: false);
            final currentUserId = authProv.userData?.id;
            final userInfo = regProvider.getUserPlayerInfo(players: status.players, currentUserId: currentUserId);
            final bool isUserRegistered = userInfo != null; // type != guest

            if (isUserRegistered) {
              // Mostrar botón de Desinscribir
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: regProvider.isLoading
                      ? null
                      : () async {
                          await regProvider.cancelRegistrationFromHome(context, widget.fulbito.id);
                          if (!mounted) return;
                          if (authProv.token != null) {
                            await Provider.of<FulbitoProvider>(context, listen: false).loadFulbitoDetails(
                              widget.fulbito,
                              authProv.phoneNumber ?? '',
                              authProv.token!,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ).copyWith(
                    backgroundColor: MaterialStateProperty.all(Colors.transparent),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: regProvider.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'DESINSCRIBIRSE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }

            // Mostrar botón Inscribirse
            return SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: regProvider.isLoading
                    ? null
                    : () async {
                        final success = await regProvider.registerForFulbito(context, widget.fulbito.id);
                        if (!mounted) return;
                        if (success && authProv.token != null) {
                          await Provider.of<FulbitoProvider>(context, listen: false).loadFulbitoDetails(
                            widget.fulbito,
                            authProv.phoneNumber ?? '',
                            authProv.token!,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: regProvider.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'INSCRIBIRSE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Botón Invitar (debajo de inscribirse, mismo ancho/estilo degradado)
        if (status.invitationOpen) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InviteGuestPlayerScreen(fulbito: widget.fulbito),
                  ),
                );
                final authProv = Provider.of<auth_provider.AuthProvider>(context, listen: false);
                if (authProv.token != null && mounted) {
                  await Provider.of<FulbitoProvider>(context, listen: false).loadFulbitoDetails(
                    widget.fulbito,
                    authProv.phoneNumber ?? '',
                    authProv.token!,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'INVITAR JUGADOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        // Botón Armar Equipos
        _buildCreateTeamsButton(),
        const SizedBox(height: 24),
        // Lista de jugadores en solo lectura
        _buildRegisteredPlayersList(status, readOnly: true),

        if (status.invitationOpen) ...[
          const SizedBox(height: 16),
          // Botón Invitar Invitado (solo si invitation_open = true)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InviteGuestPlayerScreen(fulbito: widget.fulbito),
                  ),
                );
                // Al volver, refrescar detalle para reflejar nuevos invitados
                final authProv = Provider.of<auth_provider.AuthProvider>(context, listen: false);
                if (authProv.token != null && mounted) {
                  await Provider.of<FulbitoProvider>(context, listen: false).loadFulbitoDetails(
                    widget.fulbito,
                    authProv.phoneNumber ?? '',
                    authProv.token!,
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: const Color(0xFF8B5CF6),
              ),
              icon: const Icon(Icons.group_add),
              label: const Text('INVITAR JUGADOR'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUserRegisteredContent(RegistrationStatus status) {
    return Column(
      children: [
        // Botón de cancelar inscripción
        Consumer<FulbitoInscriptionProvider>(
          builder: (context, inscriptionProvider, child) {
            return SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: inscriptionProvider.isLoading 
                    ? null 
                    : () => inscriptionProvider.showCancelRegistrationDialog(
                        context, 
                        () => inscriptionProvider.cancelRegistration(context, widget.fulbito.id)
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: inscriptionProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'CANCELAR INSCRIPCIÓN',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Botón Armar Equipos
        _buildCreateTeamsButton(),
        
        const SizedBox(height: 24),
        
        // Lista de jugadores inscritos
        _buildRegisteredPlayersList(status),
      ],
    );
  }

  Widget _buildCreateTeamsButton() {
    return Consumer<FulbitoProvider>(
      builder: (context, fulbitoProvider, child) {
        final fulbito = fulbitoProvider.currentFulbito ?? widget.fulbito;
        final registeredPlayers = fulbito.registrationStatus?.players ?? [];
        
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: registeredPlayers.isEmpty 
                ? null 
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeamsScreen(
                          registeredPlayers: registeredPlayers,
                        ),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: registeredPlayers.isEmpty 
                  ? Colors.grey 
                  : const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group, size: 20),
                const SizedBox(width: 8),
                Text(
                  registeredPlayers.isEmpty 
                      ? 'NO HAY JUGADORES'
                      : 'ARMAR EQUIPOS',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegisteredPlayersList(RegistrationStatus status, {bool readOnly = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jugadores Inscritos (${status.registeredCount})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 16),
          if (status.players.isEmpty)
            const Text(
              'No hay jugadores inscritos aún',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            )
          else
            ...status.players.map((player) => _buildRegisteredPlayerItemReadOnly(player)),
        ],
      ),
    );
  }

  Widget _buildRegisteredPlayerItemReadOnly(Map<String, dynamic> player) {
    final position = player['position'] ?? 0;
    final username = player['username'] ?? '';
    final photoUrl = player['photo_url'] ?? '';
    final type = (player['type'] ?? '').toString();
    final authProv = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final int? currentUserId = authProv.userData?.id;
    // Debug
    // ignore: avoid_print
    print('[FulbitoDetails] myGuest? type=$type, player[userid]=${player['userid']} vs currentUserId=$currentUserId');
    final bool isMyGuest = type == 'guest' && player['userid'] == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF8B5CF6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$position',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            clipBehavior: Clip.antiAlias,
            child: photoUrl.isNotEmpty
                ? Image.network(
                    '${ApiConfig.baseUrl}$photoUrl',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, color: Colors.grey);
                    },
                  )
                : const Icon(Icons.person, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              username,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),
          if (isMyGuest) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                if (authProv.token != null) {
                  final bool? confirmed = await _showConfirmUnregisterGuest(username);
                  if (confirmed == true) {
                    final unregisterProvider = Provider.of<UnregisterGuestProvider>(context, listen: false);
                    await unregisterProvider.unregisterGuest(
                      token: authProv.token!,
                      fulbitoId: widget.fulbito.id,
                      guestName: username,
                      context: context,
                    );
                    if (mounted) {
                      await Provider.of<FulbitoProvider>(context, listen: false).loadFulbitoDetails(
                        widget.fulbito,
                        authProv.phoneNumber ?? '',
                        authProv.token!,
                      );
                    }
                  }
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(Icons.group_remove, color: Colors.white, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<bool?> _showConfirmUnregisterGuest(String guestName) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Desinscribir invitado',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('¿Deseas desinscribir a "$guestName"? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
              child: const Text('Desinscribir'),
            ),
          ],
        );
      },
    );
  }


  String _formatTime(String time) {
    if (time.length > 5) {
      return time.substring(0, 5); // HH:MM
    }
    return time;
  }

  String _formatNextMatch(RegistrationStatus status) {
    try {
      if (status.nextMatchDate.isEmpty || status.nextMatchHour.isEmpty) return '${status.nextMatchDate} ${status.nextMatchHour}';
      final dt = DateTime.parse('${status.nextMatchDate}T${status.nextMatchHour}');
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$d/$m/$y $hh:$mm';
    } catch (e) {
      return '${status.nextMatchDate} ${status.nextMatchHour}';
    }
  }

  String _formatOpensAt(String opensAt) {
    try {
      final date = DateTime.parse(opensAt);
      final d = date.day.toString().padLeft(2, '0');
      final m = date.month.toString().padLeft(2, '0');
      final y = date.year.toString();
      final hh = date.hour.toString().padLeft(2, '0');
      final mm = date.minute.toString().padLeft(2, '0');
      return '$d/$m/$y $hh:$mm';
    } catch (e) {
      return opensAt;
    }
  }

  void _ensureTimersFromStatus(RegistrationStatus status) {
    // Registrar cuenta regresiva si faltan menos de ~58 min y más de 0
    if (_regCountdown == null && status.timeUntilOpen > 0 && status.timeUntilOpen < 3500) {
      // Colchón +2s para asegurar que el backend ya aplicó el cambio
      _startCountdown(isRegistration: true, seconds: status.timeUntilOpen + 2);
    }
    if (_invCountdown == null && status.invitationTimeUntilOpen > 0 && status.invitationTimeUntilOpen < 3500) {
      _startCountdown(isRegistration: false, seconds: status.invitationTimeUntilOpen + 1);
    }
  }

  void _startCountdown({required bool isRegistration, required int seconds}) {
    if (isRegistration) {
      _regCountdown = seconds;
      _regDeadline = DateTime.now().add(Duration(seconds: seconds));
    } else {
      _invCountdown = seconds;
      _invDeadline = DateTime.now().add(Duration(seconds: seconds));
    }
    // Ticker para redibujar
    Future.microtask(() async {
      while (mounted && ((_regCountdown ?? 0) > 0 || (_invCountdown ?? 0) > 0)) {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          if (_regDeadline != null) {
            _regCountdown = _regDeadline!.difference(DateTime.now()).inSeconds;
            if (_regCountdown! <= 0) _regCountdown = null;
          }
          if (_invDeadline != null) {
            _invCountdown = _invDeadline!.difference(DateTime.now()).inSeconds;
            if (_invCountdown! <= 0) _invCountdown = null;
          }
          _ticker.value++;
        });

        // Si la cuenta de inscripción llegó a 0, refrescar una vez la pantalla
        if (!_isRefreshingOnZero && (_regCountdown == null)) {
          _isRefreshingOnZero = true;
          final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
          final fulbitoProvider = Provider.of<FulbitoProvider>(context, listen: false);
          if (authProvider.token != null) {
            await fulbitoProvider.loadFulbitoDetails(
              widget.fulbito,
              authProvider.phoneNumber ?? '',
              authProvider.token!,
            );
          }
          final updated = fulbitoProvider.currentFulbito?.registrationStatus;
          if (updated != null) {
            setState(() {
              _regDeadline = null;
              _invDeadline = null;
              _regCountdown = null;
              _invCountdown = null;
            });
            _ensureTimersFromStatus(updated);
          }
          _isRefreshingOnZero = false;
        }
      }
    });
  }

  String _formatCountdown(int seconds) {
    if (seconds < 0) seconds = 0;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final ss = s.toString().padLeft(2, '0');
    return "$m'${ss}\"";
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
                  ? const Color(0xFF8B5CF6).withOpacity(0.25)
                  : const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF8B5CF6).withOpacity(0.2),
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
                if (isSelected) ...[
                  Container(
                    width: 6,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
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
                        color: isAdmin ? const Color(0xFFEF4444) : const Color(0xFF7C3AED),
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

}
