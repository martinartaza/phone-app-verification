import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth.dart' as auth_provider;
import '../../providers/invitations.dart';
import '../../providers/home.dart';
import '../../widgets/maintenance_modal.dart';
import '../fulbito/fulbito_details.dart';
import '../invite_guest_player_screen.dart';
import '../vote_player_screen.dart';
import '../create_fulbito.dart';
import '../invite_player.dart';
import '../../models/network.dart';
import '../../providers/registration.dart';
import '../../providers/fulbito/fulbito_inscription_provider.dart';
import '../../providers/unregister_guest.dart';

class FulbitosTab extends StatelessWidget {
  const FulbitosTab({Key? key}) : super(key: key);

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

          if (invProvider.isFulbitosEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.sports_soccer,
                    size: 64,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay fulbitos programados',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Los fulbitos aparecerán aquí cuando se programen',
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
          final filteredPendingFulbitos = homeProvider.filterFulbitos(invProvider.fulbitosData.pendingFulbitos);
          final filteredMyFulbitos = homeProvider.filterFulbitos(invProvider.fulbitosData.myFulbitos);
          final filteredAcceptFulbitos = homeProvider.filterFulbitos(invProvider.fulbitosData.acceptFulbitos);

          // Si hay búsqueda activa y no hay resultados
          if (!homeProvider.hasFulbitosResults(
            pendingFulbitos: invProvider.fulbitosData.pendingFulbitos,
            myFulbitos: invProvider.fulbitosData.myFulbitos,
            acceptFulbitos: invProvider.fulbitosData.acceptFulbitos,
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
              if (filteredPendingFulbitos.isNotEmpty)
                _buildCenteredDividerTitle('Invitaciones a Fulbitos'),
              ...filteredPendingFulbitos.map((f) => FulbitoItem(
                    fulbito: f,
                    isPending: true,
                  )),
              const SizedBox(height: 16),
              if (filteredMyFulbitos.isNotEmpty || filteredAcceptFulbitos.isNotEmpty)
                _buildCenteredDividerTitle('Mis Fulbitos'),
              ...[
                ...filteredMyFulbitos,
                ...filteredAcceptFulbitos,
              ].map((f) => FulbitoItem(
                    fulbito: f,
                    trailing: _buildFulbitoTrailing(context, f),
                  )),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCenteredDividerTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(
            child: Divider(thickness: 1, color: Color(0xFFE5E7EB)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Expanded(
            child: Divider(thickness: 1, color: Color(0xFFE5E7EB)),
          ),
        ],
      ),
    );
  }

  Widget _buildFulbitoTrailing(BuildContext context, Fulbito fulbito) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón de votar (comentado temporalmente - VotePlayerScreen solo acepta NetworkUser)
        // GestureDetector(
        //   onTap: () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //         builder: (context) => VotePlayerScreen(fulbito: fulbito),
        //       ),
        //     );
        //   },
        //   child: Container(
        //     width: 32,
        //     height: 32,
        //     decoration: BoxDecoration(
        //       color: const Color(0xFF3B82F6),
        //       shape: BoxShape.circle,
        //       boxShadow: [
        //         BoxShadow(
        //           color: const Color(0xFF3B82F6).withOpacity(0.3),
        //           blurRadius: 4,
        //           offset: const Offset(0, 2),
        //         ),
        //       ],
        //     ),
        //     child: const Icon(
        //       Icons.how_to_vote,
        //       color: Colors.white,
        //       size: 18,
        //     ),
        //   ),
        // ),
        const SizedBox(width: 8),
        // Botón de ver detalles
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FulbitoDetailsScreen(fulbito: fulbito),
              ),
            );
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.visibility,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class FulbitoItem extends StatefulWidget {
  final Fulbito fulbito;
  final bool isPending;
  final Widget? trailing;

  const FulbitoItem({
    Key? key,
    required this.fulbito,
    this.isPending = false,
    this.trailing,
  }) : super(key: key);

  @override
  State<FulbitoItem> createState() => _FulbitoItemState();
}

class _FulbitoItemState extends State<FulbitoItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con título y estado
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.fulbito.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    if (widget.isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: const Text(
                          'PENDIENTE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    // Botón de ver detalles (icono del ojo) - Separado del onTap del card
                    if (widget.trailing != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FulbitoDetailsScreen(fulbito: widget.fulbito),
                            ),
                          );
                        },
                        child: widget.trailing!,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                
                // Información básica del fulbito (siempre visible)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.fulbito.place,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.fulbito.day} - ${widget.fulbito.hour}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.fulbito.capacity} jugadores',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                // Contenido expandible
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  // Estado de inscripción
                  _buildRegistrationStatus(context),
                ],
                
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationStatus(BuildContext context) {
    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userData?.id;
    
    // Usar el provider para determinar qué botón mostrar
    final regProvider = Provider.of<RegistrationProvider>(context, listen: false);
    final bool showInscriptionButton = regProvider.shouldShowInscriptionButton(
      players: widget.fulbito.registrationStatus?.players ?? [],
      currentUserId: currentUserId,
      registrationOpen: widget.fulbito.registrationStatus?.registrationOpen ?? false,
      userRegistered: widget.fulbito.registrationStatus?.userRegistered, // Usar el campo del sync
    );
    
    // Obtener información del usuario inscrito
    final userPlayerInfo = regProvider.getUserPlayerInfo(
      players: widget.fulbito.registrationStatus?.players ?? [],
      currentUserId: currentUserId,
    );
    
    final int? userPosition = userPlayerInfo?['position'];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (widget.fulbito.registrationStatus?.registrationOpen ?? false) ? const Color(0xFFF0FDF4) : const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (widget.fulbito.registrationStatus?.registrationOpen ?? false) ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                (widget.fulbito.registrationStatus?.registrationOpen ?? false) ? Icons.check_circle : Icons.schedule,
                size: 16,
                color: (widget.fulbito.registrationStatus?.registrationOpen ?? false) ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Text(
                (widget.fulbito.registrationStatus?.registrationOpen ?? false) ? 'Inscripción ABIERTA' : 'Inscripción CERRADA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: (widget.fulbito.registrationStatus?.registrationOpen ?? false) ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
              // Botón de inscripción (determinado por el provider)
              if (showInscriptionButton) ...[
                const Spacer(),
                Consumer<RegistrationProvider>(
                  builder: (context, regProvider, child) {
                    return GestureDetector(
                      onTap: regProvider.isLoading ? null : () => regProvider.registerForFulbito(context, widget.fulbito.id),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: regProvider.isLoading ? Colors.grey : const Color(0xFF8B5CF6),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (regProvider.isLoading ? Colors.grey : const Color(0xFF8B5CF6)).withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: regProvider.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.person_add_alt_1,
                                color: Colors.white,
                                size: 18,
                              ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          
          // Información de inscripción
          Row(
            children: [
              Icon(Icons.people, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Inscritos: ${(widget.fulbito.registrationStatus?.registeredCount ?? 0)}/${(widget.fulbito.registrationStatus?.capacity ?? 0)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          // Información de cuándo se abre la inscripción (solo si está cerrada)
          if (!(widget.fulbito.registrationStatus?.registrationOpen ?? false)) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.schedule,
                          size: 16,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Inscripción se habilita',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDateTime((widget.fulbito.registrationStatus?.opensAt ?? '')),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1F2937),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if ((widget.fulbito.registrationStatus?.invitationOpensAt) != null && widget.fulbito.registrationStatus != null && _shouldShowInvitationInfo(widget.fulbito.registrationStatus!)) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.group_add,
                            size: 16,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Invitaciones se habilitan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDateTime((widget.fulbito.registrationStatus?.invitationOpensAt)!),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1F2937),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          // Información del usuario inscrito (solo si la inscripción está abierta)
          if ((widget.fulbito.registrationStatus?.registrationOpen ?? false) && (userPlayerInfo != null || (widget.fulbito.registrationStatus?.userRegistered) == true)) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    userPosition != null 
                        ? 'Tu posición: $userPosition'
                        : 'Inscrito como jugador',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Botón de cancelar inscripción
                Consumer<RegistrationProvider>(
                  builder: (context, regProvider, child) {
                    return GestureDetector(
                      onTap: regProvider.isLoading ? null : () => regProvider.cancelRegistrationFromHome(context, widget.fulbito.id),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: regProvider.isLoading ? Colors.grey : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (regProvider.isLoading ? Colors.grey : const Color(0xFFEF4444)).withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: regProvider.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.person_remove,
                                color: Colors.white,
                                size: 18,
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
          
          
          // Estado de invitaciones de invitados (solo si la inscripción está abierta)
          if ((widget.fulbito.registrationStatus?.registrationOpen ?? false) && (widget.fulbito.registrationStatus?.invitationOpen ?? false)) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  (widget.fulbito.registrationStatus?.invitationOpen ?? false) ? Icons.person_add_alt : Icons.schedule,
                  size: 14,
                  color: (widget.fulbito.registrationStatus?.invitationOpen ?? false) ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    (widget.fulbito.registrationStatus?.invitationOpen ?? false) 
                        ? 'Invitaciones de invitados: ABIERTAS'
                        : 'Invitaciones de invitados: CERRADAS',
                    style: TextStyle(
                      fontSize: 12,
                      color: (widget.fulbito.registrationStatus?.invitationOpen ?? false) ? const Color(0xFF10B981) : Colors.grey[600],
                      fontWeight: (widget.fulbito.registrationStatus?.invitationOpen ?? false) ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                // Botón de invitar jugador (solo si las invitaciones están habilitadas)
                if ((widget.fulbito.registrationStatus?.invitationOpen ?? false)) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InviteGuestPlayerScreen(fulbito: widget.fulbito),
                        ),
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = dateTime.difference(now);
      
      if (difference.inDays > 0) {
        return 'En ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return 'En ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
      } else if (difference.inMinutes > 0) {
        return 'En ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
      } else {
        return 'Ahora';
      }
    } catch (e) {
      return dateTimeString;
    }
  }

  bool _shouldShowInvitationInfo(RegistrationStatus status) {
    if (status.invitationOpensAt == null) return false;
    
    try {
      final invitationTime = DateTime.parse(status.invitationOpensAt!);
      final now = DateTime.now();
      final difference = invitationTime.difference(now);
      
      // Mostrar si la invitación se abre en las próximas 24 horas
      return difference.inHours <= 24 && difference.inHours >= 0;
    } catch (e) {
      return false;
    }
  }
}
