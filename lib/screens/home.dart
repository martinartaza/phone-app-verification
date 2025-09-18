import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart' as auth_provider;
import '../providers/profile.dart';
import '../providers/invitations.dart';
import '../models/network.dart';
import '../widgets/maintenance_modal.dart';
import 'vote_player_screen.dart';
import 'create_fulbito.dart';
import 'invite_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    
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
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  // Métodos de filtrado
  List<Fulbito> _filterFulbitos(List<Fulbito> fulbitos) {
    if (_searchQuery.isEmpty) return fulbitos;
    
    return fulbitos.where((fulbito) {
      return fulbito.name.toLowerCase().contains(_searchQuery) ||
             fulbito.place.toLowerCase().contains(_searchQuery) ||
             fulbito.day.toLowerCase().contains(_searchQuery) ||
             fulbito.hour.toLowerCase().contains(_searchQuery) ||
             fulbito.ownerName.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  List<NetworkUser> _filterNetworkUsers(List<NetworkUser> users) {
    if (_searchQuery.isEmpty) return users;
    
    return users.where((user) {
      return user.username.toLowerCase().contains(_searchQuery) ||
             user.phone.toLowerCase().contains(_searchQuery);
    }).toList();
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
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Buscar...',
                  hintStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.search, color: Colors.white70, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
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
      child: Consumer<InvitationsProvider>(
        builder: (context, invProvider, child) {
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

          // Filtrar datos según la búsqueda
          final filteredPendingFulbitos = _filterFulbitos(invProvider.fulbitosData.pendingFulbitos);
          final filteredMyFulbitos = _filterFulbitos(invProvider.fulbitosData.myFulbitos);
          final filteredAcceptFulbitos = _filterFulbitos(invProvider.fulbitosData.acceptFulbitos);

          // Si hay búsqueda activa y no hay resultados
          if (_searchQuery.isNotEmpty && 
              filteredPendingFulbitos.isEmpty && 
              filteredMyFulbitos.isEmpty && 
              filteredAcceptFulbitos.isEmpty) {
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
                    trailing: f.isOwner
                        ? const _CircleIcon(color: Color(0xFF8B5CF6), icon: Icons.admin_panel_settings)
                        : const _CircleIcon(color: Color(0xFF3B82F6), icon: Icons.visibility),
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
      child: Consumer<InvitationsProvider>(
        builder: (context, invProvider, child) {
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

          // Filtrar datos según la búsqueda
          final filteredInvitationPending = _filterNetworkUsers(invProvider.networkData.invitationPending);
          final filteredNetwork = _filterNetworkUsers(invProvider.networkData.network);

          // Si hay búsqueda activa y no hay resultados
          if (_searchQuery.isNotEmpty && 
              filteredInvitationPending.isEmpty && 
              filteredNetwork.isEmpty) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
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
                if (widget.invitationMessage != null && widget.invitationMessage!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.invitationMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF374151),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.isPending && widget.invitationId != null)
            _buildActionButtons()
          else if (widget.trailing != null)
            widget.trailing!,
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
    return Container(
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
                      widget.fulbito.ownerName,
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
          const SizedBox(height: 12),
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
              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${_formatDay(widget.fulbito.day)} ${_formatTime(widget.fulbito.hour)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
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
}