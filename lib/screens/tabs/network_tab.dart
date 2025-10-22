import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth.dart' as auth_provider;
import '../../providers/invitations.dart';
import '../../providers/home.dart';
import '../../widgets/maintenance_modal.dart';
import '../vote_player_screen.dart';

class NetworkTab extends StatelessWidget {
  const NetworkTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Consumer2<InvitationsProvider, HomeProvider>(
        builder: (context, invProvider, homeProvider, child) {
          if (invProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (invProvider.error != null) {
            if (invProvider.error == 'MAINTENANCE_MODE') {
              // Mostrar modal de mantenimiento
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
                if (authProvider.token != null) {
                  MaintenanceModal.show(context, onRetry: () => invProvider.load(authProvider.token!));
                }
              });
              return const Center(
                child: Text(
                  'MAINTENANCE_MODE',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
            return Center(
              child: Text(
                invProvider.error!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (invProvider.isNetworkEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.group,
                    size: 64,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay jugadores en tu red',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Los jugadores de tu grupo aparecerán aquí',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          }

          // Filtrar datos según la búsqueda usando el provider
          final filteredInvitationPending = homeProvider.filterNetworkUsers(invProvider.networkData.invitationPending);
          final filteredNetwork = homeProvider.filterNetworkUsers(invProvider.networkData.network);

          // Si hay búsqueda activa y no hay resultados
          if (!homeProvider.hasUsersResults(
            invitationPending: invProvider.networkData.invitationPending,
            network: invProvider.networkData.network,
          )) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off,
                    size: 64,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No se encontraron resultados',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Intenta con otros términos de búsqueda',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (filteredInvitationPending.isNotEmpty)
                _buildSectionTitle('Invitaciones'),
              ...filteredInvitationPending.map((u) => InvitationItem(
                    username: u.username,
                    phone: u.phone,
                    photoUrl: u.photoUrl,
                    invitationMessage: u.invitationMessage,
                    invitationId: u.invitationId,
                    isPending: true,
                  )),

              if (filteredNetwork.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Tu red'),
                ...filteredNetwork.map((u) => InvitationItem(
                      username: u.username,
                      phone: u.phone,
                      photoUrl: u.photoUrl,
                      invitationMessage: null, // No mostrar mensaje en "Tu red"
                      trailing: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VotePlayerScreen(player: u),
                            ),
                          );
                        },
                        child: const CircleIcon(color: Color(0xFF3B82F6), icon: Icons.visibility),
                      ),
                    )),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}

class InvitationItem extends StatefulWidget {
  final String username;
  final String phone;
  final String? photoUrl;
  final String? invitationMessage;
  final Widget? trailing;
  final int? invitationId;
  final bool isPending;

  const InvitationItem({
    Key? key,
    required this.username,
    required this.phone,
    required this.photoUrl,
    this.invitationMessage,
    this.trailing,
    this.invitationId,
    this.isPending = false,
  }) : super(key: key);

  @override
  State<InvitationItem> createState() => _InvitationItemState();
}

class _InvitationItemState extends State<InvitationItem> {
  bool _isProcessing = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.isPending) {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header básico (siempre visible)
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: widget.photoUrl != null && widget.photoUrl!.isNotEmpty
                      ? Image.network(
                          widget.photoUrl!,
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
                        widget.username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.phone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isPending && widget.invitationId != null)
                  _buildActionButtons()
                else if (widget.trailing != null)
                  widget.trailing!,
              ],
            ),
            
            // Contenido expandido (solo si está expandido y es una invitación pendiente)
            if (_isExpanded && widget.isPending && widget.invitationMessage != null && widget.invitationMessage!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildExpandedMessage(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mensaje de invitación:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.invitationMessage!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isProcessing) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _acceptInvitation,
          child: const CircleIcon(
            color: Color(0xFF10B981),
            icon: Icons.check,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _rejectInvitation,
          child: const CircleIcon(
            color: Color(0xFFEF4444),
            icon: Icons.close,
          ),
        ),
      ],
    );
  }

  Future<void> _acceptInvitation() async {
    if (widget.invitationId == null) return;

    setState(() {
      _isProcessing = true;
    });

    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final invitationsProvider = Provider.of<InvitationsProvider>(context, listen: false);

    if (authProvider.token != null) {
      final result = await invitationsProvider.handleAcceptInvitation(
        authProvider.token!,
        widget.invitationId!,
        context,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['isError'] ? Colors.red : Colors.green,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _rejectInvitation() async {
    if (widget.invitationId == null) return;

    setState(() {
      _isProcessing = true;
    });

    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final invitationsProvider = Provider.of<InvitationsProvider>(context, listen: false);

    if (authProvider.token != null) {
      final result = await invitationsProvider.handleRejectInvitation(
        authProvider.token!,
        widget.invitationId!,
        context,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['isError'] ? Colors.red : Colors.orange,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}

class CircleIcon extends StatelessWidget {
  final Color color;
  final IconData icon;
  const CircleIcon({Key? key, required this.color, required this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
