import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fulbito/fulbito_provider.dart';
import '../../providers/fulbito/invite_players_provider.dart';
import '../../providers/auth.dart' as auth_provider;
import '../../models/player.dart';
import '../../widgets/dual_hexagon_chart.dart';
import '../../config/api_config.dart';

class InvitePlayersScreen extends StatefulWidget {
  const InvitePlayersScreen({Key? key}) : super(key: key);

  @override
  State<InvitePlayersScreen> createState() => _InvitePlayersScreenState();
}

class _InvitePlayersScreenState extends State<InvitePlayersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  Player? _selected;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Limpiar el estado del provider cuando se cierre la pantalla
    final inviteProvider = Provider.of<InvitePlayersProvider>(context, listen: false);
    inviteProvider.clearState();
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
        title: const Text(
          'Invitar jugadores',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<FulbitoProvider>(
          builder: (context, fulbitoProvider, _) {
            final List<_InviteRow> merged = [
              ...fulbitoProvider.enabledToRegister.map((p) => _InviteRow(player: p, state: _InviteState.invitable)),
              ...fulbitoProvider.pendingAccept.map((p) => _InviteRow(player: p, state: _InviteState.pending)),
              ...fulbitoProvider.rejected.map((p) => _InviteRow(player: p, state: _InviteState.rejected)),
              ...fulbitoProvider.players.map((p) => _InviteRow(player: p, state: _InviteState.accepted)),
            ];

            // Merge and filter according to query
            final List<_InviteRow> filtered = _applyFilter(merged);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Buscador (estilo similar al home)
                  _buildSearchField(),

                  const SizedBox(height: 20),

                  // Hexágono placeholder (simple caja por ahora)
                  _buildHexagon(),

                  const SizedBox(height: 24),

                  // Título lista
                  const Text(
                    'Resultados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (fulbitoProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (fulbitoProvider.error != null)
                    Text(
                      fulbitoProvider.error!,
                      style: const TextStyle(color: Colors.red),
                    )
                  else if (filtered.isEmpty)
                    const Text(
                      'No hay jugadores para mostrar',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    )
                  else
                    Column(
                      children: filtered.map((row) => _buildInviteItem(row)).toList(),
                    ),

                  // Sección de invitación
                  if (filtered.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildInvitationSection(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o teléfono',
                border: InputBorder.none,
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
              },
              child: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
            ),
        ],
      ),
    );
  }

  Widget _buildHexagon() {
    final Map<String, double> average = _selected?.averageSkills ?? {};
    return Center(
      child: DualHexagonChart(
        selfPerceptionSkills: const {},
        averageOpinionSkills: average,
        numberOfOpinions: 0,
        size: 200,
      ),
    );
  }

  Widget _buildInviteItem(_InviteRow row) {
    final Player player = row.player;
    return Consumer<InvitePlayersProvider>(
      builder: (context, inviteProvider, child) {
        final bool isSelected = inviteProvider.isPlayerSelected(player.id);

    // Estilos por estado
    Color bgColor;
    Color borderColor;
    Widget trailing;

    switch (row.state) {
      case _InviteState.invitable:
        bgColor = isSelected 
            ? const Color(0xFFDBEAFE) // azul más intenso cuando seleccionado
            : const Color(0xFFEFF6FF); // azul muy claro
        borderColor = isSelected 
            ? const Color(0xFF3B82F6) // azul más intenso cuando seleccionado
            : const Color(0xFF93C5FD);
        trailing = _buildInviteButton(
          isSelected: isSelected,
          onTap: () => inviteProvider.togglePlayerSelection(player.id),
        );
        break;
      case _InviteState.pending:
        bgColor = const Color(0xFFECFDF5); // verde muy claro
        borderColor = const Color(0xFF6EE7B7);
        trailing = _pill(
          icon: Icons.hourglass_top,
          label: 'Pendiente',
          color: const Color(0xFF059669),
          bg: const Color(0xFFD1FAE5),
        );
        break;
      case _InviteState.rejected:
        bgColor = const Color(0xFFFFF1F2); // rojo muy claro
        borderColor = const Color(0xFFFCA5A5);
        trailing = _pill(
          icon: Icons.block,
          label: 'Rechazó',
          color: const Color(0xFFDC2626),
          bg: const Color(0xFFFEE2E2),
        );
        break;
      case _InviteState.accepted:
        bgColor = const Color(0xFFF9FAFB); // gris claro
        borderColor = Colors.grey.shade300;
        trailing = _pill(
          icon: Icons.check_circle,
          label: 'Aceptó',
          color: const Color(0xFF16A34A),
          bg: const Color(0xFFD1FAE5),
        );
        break;
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selected = player;
        });
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
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
                  player.username.isNotEmpty ? player.username : 'Nombre del jugador',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  player.phone.isNotEmpty ? player.phone : '+540000000000',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    ),
    );
      },
    );
  }

  Widget _pill({required IconData icon, required String label, required Color color, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteButton({required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE0E7FF),
          borderRadius: BorderRadius.circular(999),
          border: isSelected 
              ? Border.all(color: const Color(0xFF1D4ED8), width: 2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check : Icons.person_add,
              color: isSelected ? Colors.white : const Color(0xFF2563EB),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              isSelected ? 'Seleccionado' : 'Invitar',
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2563EB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInvitationSection() {
    return Consumer<InvitePlayersProvider>(
      builder: (context, inviteProvider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label "Invitación:"
              const Text(
                'Invitación:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 12),
              
              // Textarea
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: TextField(
                  onChanged: inviteProvider.updateInvitationMessage,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu mensaje de invitación aquí...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Botón enviar invitaciones
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: inviteProvider.hasSelectedPlayers ? () => _sendInvitations() : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inviteProvider.hasSelectedPlayers 
                        ? const Color(0xFF3B82F6) 
                        : const Color(0xFF9CA3AF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    inviteProvider.hasSelectedPlayers 
                        ? 'Enviar invitaciones (${inviteProvider.selectedPlayers.length})'
                        : 'Selecciona jugadores para invitar',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendInvitations() async {
    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final fulbitoProvider = Provider.of<FulbitoProvider>(context, listen: false);
    final inviteProvider = Provider.of<InvitePlayersProvider>(context, listen: false);
    
    if (authProvider.token == null) {
      _showError('No hay token de autenticación');
      return;
    }

    // Obtener todos los jugadores
    final allPlayers = [
      ...fulbitoProvider.enabledToRegister,
      ...fulbitoProvider.pendingAccept,
      ...fulbitoProvider.rejected,
      ...fulbitoProvider.players,
    ];

    // Llamar al método del provider
    final success = await inviteProvider.sendInvitations(
      token: authProvider.token!,
      fulbitoId: fulbitoProvider.currentFulbito?.id ?? 0,
      allPlayers: allPlayers,
    );

    if (success) {
      // Mostrar mensaje de éxito
      _showSuccess('Invitaciones enviadas exitosamente');
      
      // Recargar datos del fulbito
      await fulbitoProvider.loadFulbitoDetails(
        fulbitoProvider.currentFulbito!, 
        authProvider.phoneNumber!, 
        authProvider.token!
      );
      
      // Navegar de vuelta a la pestaña de detalles
      Navigator.pop(context); // Cerrar pantalla de invitación
    } else {
      _showError(inviteProvider.error ?? 'Error al enviar invitaciones');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

enum _InviteState { invitable, pending, rejected, accepted }

class _InviteRow {
  final Player player;
  final _InviteState state;
  _InviteRow({required this.player, required this.state});
}

extension on Player {
  bool matches(String q) {
    if (q.isEmpty) return true;
    final name = username.toLowerCase();
    final phoneLc = phone.toLowerCase();
    return name.contains(q) || phoneLc.contains(q);
  }
}

extension _FilterExt on _InviteRow {
  bool matches(String q) => player.matches(q);
}

extension _FilterList on _InvitePlayersScreenState {
  List<_InviteRow> _applyFilter(List<_InviteRow> input) {
    if (_query.isEmpty) return input;
    return input.where((r) => r.matches(_query)).toList();
  }
}




