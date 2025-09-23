import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart' as auth_provider;
import '../providers/profile.dart';
import '../providers/invitations.dart';
import '../providers/home.dart';
import '../providers/registration.dart';
import '../models/network.dart';
import '../widgets/maintenance_modal.dart';
import '../config/api_config.dart';
import 'vote_player_screen.dart';
import 'create_fulbito.dart';
import 'invite_player.dart';
import 'fulbito/fulbito_details.dart';
import 'invite_guest_player_screen.dart';
import '../providers/unregister_guest.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  int _refreshCooldown = 0;
  Timer? _refreshTimer;
  int? _nextEventSeconds;
  Timer? _nextEventTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    
    // Cargar perfil al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final invitationsProvider = Provider.of<InvitationsProvider>(context, listen: false);
      
      if (authProvider.token != null) {
        profileProvider.loadProfile(authProvider.token!);
        await invitationsProvider.load(authProvider.token!);
        _updateNextEventFromProvider();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _nextEventTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final authProv = Provider.of<auth_provider.AuthProvider>(context, listen: false);
      if (authProv.token != null) {
        try {
          await Provider.of<InvitationsProvider>(context, listen: false).load(authProv.token!);
          _updateNextEventFromProvider();
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // No permitir volver atrás desde home
        // Esto evita que el usuario regrese a phone_input o verification
      },
      child: Scaffold(
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

  void _handleRefreshTap() async {
    if (_refreshCooldown > 0) return;

    final authProv = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    if (authProv.token != null) {
      // Recargar invitaciones/fulbitos (GET all)
      await Provider.of<InvitationsProvider>(context, listen: false).load(authProv.token!);
      _updateNextEventFromProvider();
      // También podemos refrescar el perfil si fuera necesario
      // await Provider.of<ProfileProvider>(context, listen: false).loadProfile(authProv.token!);
    }

    _startRefreshCooldown();
  }

  void _startRefreshCooldown() {
    setState(() {
      _refreshCooldown = 10;
    });

    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _refreshCooldown = (_refreshCooldown - 1).clamp(0, 10);
        if (_refreshCooldown == 0) {
          timer.cancel();
        }
      });
    });
  }

  void _updateNextEventFromProvider() {
    try {
      final invitationsProvider = Provider.of<InvitationsProvider>(context, listen: false);
      final int? nextEvent = invitationsProvider.fulbitosData.nextEvent;
      if (nextEvent != null && nextEvent > 0 && nextEvent < 3500) {
        // Añadimos 1 segundo de colchón
        _startNextEventTimer(nextEvent + 1);
      } else {
        _stopNextEventTimer();
      }
    } catch (_) {}
  }

  void _startNextEventTimer(int seconds) {
    _nextEventTimer?.cancel();
    setState(() {
      _nextEventSeconds = seconds;
    });
    _nextEventTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_nextEventSeconds != null) {
          _nextEventSeconds = _nextEventSeconds! - 1;
          if (_nextEventSeconds! <= 0) {
            _nextEventSeconds = null;
            t.cancel();
            // Al llegar a cero, refrescar la data automáticamente
            final authProv = Provider.of<auth_provider.AuthProvider>(context, listen: false);
            if (authProv.token != null) {
              Provider.of<InvitationsProvider>(context, listen: false)
                  .load(authProv.token!)
                  .then((_) => _updateNextEventFromProvider());
            }
          }
        }
      });
    });
  }

  void _stopNextEventTimer() {
    _nextEventTimer?.cancel();
    if (_nextEventSeconds != null) {
      setState(() {
        _nextEventSeconds = null;
      });
    }
  }

  String _formatCountdown(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    final String ss = s.toString().padLeft(2, '0');
    return "${m}'${ss}\"";
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
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Fulbitos'),
                if (_nextEventSeconds != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.timer, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(_formatCountdown(_nextEventSeconds!), style: const TextStyle(fontSize: 14)),
                ],
              ],
            ),
          ),
          const Tab(text: 'Jugadores'),
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

  String _formatDateTime(String dateTime) {
    try {
      // Parsear la fecha y extraer solo la parte sin timezone
      final String dateWithoutTz = dateTime.split('T')[0]; // 2025-09-22
      final String timeWithoutTz = dateTime.split('T')[1].split('-')[0]; // 08:00:00
      
      final DateTime parsed = DateTime.parse('${dateWithoutTz}T$timeWithoutTz');
      final String formatted = '${parsed.day}/${parsed.month}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      return formatted;
    } catch (e) {
      return dateTime;
    }
  }

  bool _shouldShowInvitationInfo(RegistrationStatus status) {
    try {
      // Si no hay información de invitaciones, no mostrar
      if (status.invitationOpensAt == null || status.nextMatchDate.isEmpty || status.nextMatchHour.isEmpty) {
        return false;
      }

      // Extraer fecha y hora de la invitación
      final String invitationDate = status.invitationOpensAt!.split('T')[0];
      final String invitationTime = status.invitationOpensAt!.split('T')[1].split('-')[0];
      
      // Extraer fecha y hora del partido
      final String matchDate = status.nextMatchDate;
      final String matchTime = status.nextMatchHour;
      
      // Comparar si son el mismo día y hora
      return !(invitationDate == matchDate && invitationTime == matchTime);
    } catch (e) {
      // En caso de error, mostrar la información
      return true;
    }
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
    
    // Obtener el ID del usuario actual
    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userData?.id;
    
    // Usar el provider para determinar qué botón mostrar
    final regProvider = Provider.of<RegistrationProvider>(context, listen: false);
    final bool showInscriptionButton = regProvider.shouldShowInscriptionButton(
      players: status.players,
      currentUserId: currentUserId,
      registrationOpen: status.registrationOpen,
    );
    
    // Obtener información del usuario inscrito
    final userPlayerInfo = regProvider.getUserPlayerInfo(
      players: status.players,
      currentUserId: currentUserId,
    );
    
    final int? userPosition = userPlayerInfo?['position'];
    
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
                'Inscritos: ${status.registeredCount}/${status.capacity}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          // Información de cuándo se abre la inscripción (solo si está cerrada)
          if (!status.registrationOpen) ...[
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
                              _formatDateTime(status.opensAt),
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
                  if (status.invitationOpensAt != null && _shouldShowInvitationInfo(status)) ...[
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
                                _formatDateTime(status.invitationOpensAt!),
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
          if (status.registrationOpen && userPlayerInfo != null) ...[
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
                                Icons.person_remove_alt_1,
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
          
          // Próximo partido (solo si la inscripción está abierta)
          if (status.registrationOpen && status.nextMatchDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.sports_soccer, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Próximo: ${status.nextMatchDate} ${status.nextMatchHour}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          
          // Estado de invitaciones de invitados (solo si la inscripción está abierta)
          if (status.registrationOpen && status.invitationOpensAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  status.invitationOpen ? Icons.person_add_alt : Icons.schedule,
                  size: 14,
                  color: status.invitationOpen ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    status.invitationOpen 
                        ? 'Invitaciones de invitados: ABIERTAS'
                        : 'Invitaciones de invitados: CERRADAS',
                    style: TextStyle(
                      fontSize: 12,
                      color: status.invitationOpen ? const Color(0xFF10B981) : Colors.grey[600],
                      fontWeight: status.invitationOpen ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                // Botón de invitar jugador (solo si las invitaciones están habilitadas)
                if (status.invitationOpen) ...[
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
                        Icons.group_add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            // Lista de invitados registrados
            if (_getInvitedGuests(status.players).isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._getInvitedGuests(status.players).map((guest) => _buildInvitedGuestItem(guest)),
            ],
          ],
        ],
      ),
    );
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

  // Filtrar invitados de la lista de jugadores
  List<Map<String, dynamic>> _getInvitedGuests(List<Map<String, dynamic>> players) {
    // Filtrar solo los jugadores con type: "guest"
    return players.where((player) => player['type'] == 'guest').toList();
  }

  // Construir item de invitado con botón de desinscripción
  Widget _buildInvitedGuestItem(Map<String, dynamic> guest) {
    final guestName = guest['username'] ?? 'Invitado';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Espaciador para empujar el contenido a la derecha
          const Spacer(),
          // Nombre del invitado alineado a la derecha
          Text(
            guestName,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          // Botón de desinscripción (dos personas con menos en rojo) - mismo tamaño que botones de registro
          GestureDetector(
            onTap: () {
              _showUnregisterGuestModal(guest);
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
              child: const Icon(
                Icons.group_remove,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar modal de confirmación para desinscribir invitado
  void _showUnregisterGuestModal(Map<String, dynamic> guest) {
    final guestName = guest['username'] ?? 'Invitado';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.group_remove,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Desinscribir Invitado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Estás seguro de que quieres desinscribir a este invitado?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Color(0xFF6B7280),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      guestName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Esta acción no se puede deshacer.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _unregisterGuest(guest);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Desinscribir',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Función para desinscribir invitado usando el provider
  Future<void> _unregisterGuest(Map<String, dynamic> guest) async {
    final guestName = guest['username'] ?? 'Invitado';
    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final unregisterGuestProvider = Provider.of<UnregisterGuestProvider>(context, listen: false);
    
    if (authProvider.token != null) {
      await unregisterGuestProvider.unregisterGuest(
        token: authProvider.token!,
        fulbitoId: widget.fulbito.id,
        guestName: guestName,
        context: context,
      );
    }
  }
}