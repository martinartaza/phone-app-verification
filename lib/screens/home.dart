import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth.dart' as auth_provider;
import '../providers/profile.dart';
import '../providers/invitations.dart';
import '../providers/home.dart';
import '../models/network.dart';
import '../widgets/maintenance_modal.dart';
import '../config/api_config.dart';
import 'vote_player_screen.dart';
import 'create_fulbito.dart';
import 'invite_player.dart';
import 'fulbito/fulbito_details.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Cargar perfil al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      
      if (authProvider.token != null) {
        profileProvider.loadProfile(authProvider.token!);
        Provider.of<InvitationsProvider>(context, listen: false).load(authProvider.token!);
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
      floatingActionButton: _buildAddButton(),
      body: SafeArea(
        child: Column(
          children: [
            // Header similar a WhatsApp
            _buildHeader(),
            
            // Tabs
            _buildTabBar(),
            
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFulbitosTab(),
                  _buildJugadoresTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Campo de búsqueda
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Consumer<HomeProvider>(
                builder: (context, homeProvider, child) {
                  return TextField(
                    controller: homeProvider.searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Buscar...',
                      hintStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.search, color: Colors.white70, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Foto de perfil
          Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) {
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: Image(
                      image: profileProvider.profileImageProvider,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white.withOpacity(0.2),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF059669),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Fulbitos'),
          Tab(text: 'Jugadores'),
        ],
      ),
    );
  }

  Widget _buildFulbitosTab() {
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
              ...filteredPendingFulbitos.map((f) => _FulbitoItem(
                    fulbito: f,
                    isPending: true,
                  )),
              const SizedBox(height: 16),
              if (filteredMyFulbitos.isNotEmpty || filteredAcceptFulbitos.isNotEmpty)
                _buildCenteredDividerTitle('Mis Fulbitos'),
              ...[
                ...filteredMyFulbitos,
                ...filteredAcceptFulbitos,
              ].map((f) => _FulbitoItem(
                    fulbito: f,
                    trailing: _buildFulbitoTrailing(f),
                  )),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _buildJugadoresTab() {
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
              ...filteredInvitationPending.map((u) => _InvitationItem(
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
                ...filteredNetwork.map((u) => _InvitationItem(
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
                        child: const _CircleIcon(color: Color(0xFF3B82F6), icon: Icons.visibility),
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

  Widget _buildFulbitoTrailing(Fulbito fulbito) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icono de vista (siempre presente)
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FulbitoDetailsScreen(fulbito: fulbito),
              ),
            );
          },
          child: const _CircleIcon(
            color: Color(0xFF3B82F6),
            icon: Icons.visibility,
          ),
        ),
        // Icono de admin (solo si soy el creador)
        if (fulbito.isOwner) ...[
          const SizedBox(width: 8),
          const _CircleIcon(
            color: Color(0xFF8B5CF6),
            icon: Icons.admin_panel_settings,
          ),
        ],
      ],
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        final activeTab = _tabController.index; // 0: Fulbitos, 1: Jugadores
        print('🔘 Botón + presionado en tab: $activeTab');
        
        if (activeTab == 0) {
          // Pestaña Fulbitos - Crear nuevo fulbito
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateFulbitoScreen(),
            ),
          );
        } else {
          // Pestaña Jugadores - Invitar jugador
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InvitePlayerScreen(),
            ),
          );
        }
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

class _InvitationItem extends StatefulWidget {
  final String username;
  final String phone;
  final String? photoUrl;
  final String? invitationMessage;
  final Widget? trailing;
  final int? invitationId;
  final bool isPending;

  const _InvitationItem({
    required this.username,
    required this.phone,
    required this.photoUrl,
    this.invitationMessage,
    this.trailing,
    this.invitationId,
    this.isPending = false,
  });

  @override
  State<_InvitationItem> createState() => _InvitationItemState();
}

class _InvitationItemState extends State<_InvitationItem> {
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
                      ? Image.network(widget.photoUrl!, fit: BoxFit.cover)
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
          child: const _CircleIcon(
            color: Color(0xFF10B981),
            icon: Icons.check,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _rejectInvitation,
          child: const _CircleIcon(
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

class _CircleIcon extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _CircleIcon({required this.color, required this.icon});

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

class _FulbitoItem extends StatefulWidget {
  final Fulbito fulbito;
  final Widget? trailing;
  final bool isPending;

  const _FulbitoItem({
    required this.fulbito,
    this.trailing,
    this.isPending = false,
  });

  @override
  State<_FulbitoItem> createState() => _FulbitoItemState();
}

class _FulbitoItemState extends State<_FulbitoItem> {
  bool _isProcessing = false;
  bool _isExpanded = false;

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
    if (time.length >= 5) {
      return time.substring(0, 5); // HH:MM
    }
    return time;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
                  child: widget.fulbito.ownerPhotoUrl != null && widget.fulbito.ownerPhotoUrl!.isNotEmpty
                      ? Image.network(widget.fulbito.ownerPhotoUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fulbito.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatDay(widget.fulbito.day)} ${_formatTime(widget.fulbito.hour)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isPending && widget.fulbito.invitationId != null)
                  _buildFulbitoActionButtons()
                else if (widget.trailing != null)
                  widget.trailing!,
              ],
            ),
            
            // Contenido expandido (solo si está expandido)
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              _buildExpandedContent(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Admin/Creador
        Row(
          children: [
            const Icon(Icons.admin_panel_settings, size: 16, color: Color(0xFF8B5CF6)),
            const SizedBox(width: 4),
            Text(
              widget.fulbito.ownerName,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Lugar
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
        const SizedBox(height: 8),
        
        // Capacidad
        Row(
          children: [
            Icon(Icons.group, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Capacidad: ${widget.fulbito.capacity} jugadores',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        
        // Estado de inscripción (si está disponible)
        if (widget.fulbito.registrationStatus != null) ...[
          const SizedBox(height: 12),
          _buildRegistrationStatus(),
        ],
        
        // Mensaje de invitación (solo para invitaciones pendientes)
        if (widget.isPending && widget.fulbito.message != null && widget.fulbito.message!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
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
                const SizedBox(height: 4),
                Text(
                  widget.fulbito.message!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRegistrationStatus() {
    final status = widget.fulbito.registrationStatus!;
    
    // Determinar si mostrar el icono de inscripción
    final bool showRegisterIcon = status.registrationOpen && status.userPosition == null;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: status.registrationOpen ? const Color(0xFFF0FDF4) : const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: status.registrationOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status.registrationOpen ? Icons.check_circle : Icons.schedule,
                size: 16,
                color: status.registrationOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Text(
                status.registrationOpen ? 'Inscripción ABIERTA' : 'Inscripción CERRADA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: status.registrationOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
              // Icono de inscripción (solo si está abierto y no está inscrito)
              if (showRegisterIcon) ...[
                const Spacer(),
                GestureDetector(
                  onTap: _registerForFulbito,
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
                      Icons.person_add_alt_1,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
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
                'Inscritos: ${status.registeredCount}/${status.capacity}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          // Posición del usuario (si está inscrito)
          if (status.userPosition != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Tu posición: ${status.userPosition}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          
          // Próximo partido
          if (status.nextMatchDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.sports_soccer, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Próximo: ${status.nextMatchDate} ${status.nextMatchHour}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _registerForFulbito() async {
    if (widget.fulbito.registrationStatus == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
      if (authProvider.token == null) return;

      // Llamar a la API de inscripción
      final response = await _callRegistrationAPI(authProvider.token!, widget.fulbito.id);
      
      // Debug: imprimir la respuesta
      print('🔍 API Response: $response');
      
      if (mounted) {
        if (response['success']) {
          // Mostrar modal de éxito
          print('✅ Mostrando modal de éxito');
          _showRegistrationSuccessModal(response['data']);
          
          // Recargar datos para actualizar el estado
          final invitationsProvider = Provider.of<InvitationsProvider>(context, listen: false);
          invitationsProvider.load(authProvider.token!);
        } else {
          // Mostrar modal de error
          print('❌ Mostrando modal de error');
          _showRegistrationErrorModal(response['message'] ?? 'Error al inscribirse');
        }
      }
    } catch (e) {
      if (mounted) {
        _showRegistrationErrorModal('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _callRegistrationAPI(String token, int fulbitoId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/fulbito/$fulbitoId/register/');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('🔍 HTTP Status: ${response.statusCode}');
    print('🔍 Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      // La API devuelve { "status": "success", "message": "...", "data": {...} }
      if (data['status'] == 'success') {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al inscribirse',
        };
      }
    } else {
      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Error al inscribirse',
      };
    }
  }

  void _showRegistrationErrorModal(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (BuildContext context) {
        // Auto-cerrar después de 5 segundos
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: MediaQuery.of(context).size.width * 0.85, // 85% del ancho de pantalla
            decoration: BoxDecoration(
              color: const Color(0xFFF8D7DA), // Fondo rojo claro
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDC3545), width: 3), // Borde rojo
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono de error
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC3545),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC3545).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Título de error
                  Text(
                    ApiConfig.registrationErrorTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF721C24),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Mensaje de error
                  Text(
                    errorMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF721C24),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón OK
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC3545),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRegistrationSuccessModal(Map<String, dynamic> data) {
    final position = data['position'] ?? 0;
    final role = data['role'] ?? 'player';
    final registeredAt = data['registered_at'] ?? '';
    final isSubstitute = role == 'substitute';
    
    // Determinar colores según el rol
    final backgroundColor = isSubstitute ? const Color(0xFFFFF3CD) : const Color(0xFFD4EDDA);
    final borderColor = isSubstitute ? const Color(0xFFFFC107) : const Color(0xFF28A745);
    final iconColor = isSubstitute ? const Color(0xFFFFC107) : const Color(0xFF28A745);
    final textColor = isSubstitute ? const Color(0xFF856404) : const Color(0xFF155724);
    
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (BuildContext context) {
        // Auto-cerrar después de 5 segundos
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: MediaQuery.of(context).size.width * 0.85, // 85% del ancho de pantalla
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono de éxito más grande
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      isSubstitute ? Icons.schedule : Icons.check_circle,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Título más grande
                  Text(
                    isSubstitute ? ApiConfig.registrationSubstituteTitle : ApiConfig.registrationSuccessTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Mensaje descriptivo
                  Text(
                    isSubstitute ? ApiConfig.registrationSubstituteMessage : ApiConfig.registrationSuccessMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Información de inscripción más grande
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Posición:', '$position'),
                        const SizedBox(height: 12),
                        _buildInfoRow('Rol:', isSubstitute ? 'Suplente' : 'Jugador'),
                        if (registeredAt.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow('Hora de inscripción:', _formatDateTime(registeredAt)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón OK más grande
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: iconColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String dateTime) {
    try {
      final DateTime parsed = DateTime.parse(dateTime);
      final String formatted = '${parsed.day}/${parsed.month}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      return formatted;
    } catch (e) {
      return dateTime;
    }
  }

  Widget _buildFulbitoActionButtons() {
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
          onTap: _acceptFulbito,
          child: const _CircleIcon(
            color: Color(0xFF10B981),
            icon: Icons.check,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _rejectFulbito,
          child: const _CircleIcon(
            color: Color(0xFFEF4444),
            icon: Icons.close,
          ),
        ),
      ],
    );
  }

  Future<void> _acceptFulbito() async {
    if (widget.fulbito.invitationId == null) return;

    setState(() {
      _isProcessing = true;
    });

    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final invitationsProvider = Provider.of<InvitationsProvider>(context, listen: false);

    if (authProvider.token != null) {
      final result = await invitationsProvider.handleAcceptFulbito(
        authProvider.token!,
        widget.fulbito.invitationId!,
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

  Future<void> _rejectFulbito() async {
    if (widget.fulbito.invitationId == null) return;

    setState(() {
      _isProcessing = true;
    });

    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final invitationsProvider = Provider.of<InvitationsProvider>(context, listen: false);

    if (authProvider.token != null) {
      final result = await invitationsProvider.handleRejectFulbito(
        authProvider.token!,
        widget.fulbito.invitationId!,
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