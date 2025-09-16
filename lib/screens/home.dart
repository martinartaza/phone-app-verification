import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart' as auth_provider;
import '../providers/profile.dart';
import '../providers/invitations.dart';
import '../models/network.dart';
import 'vote_player_screen.dart';

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
          // Lupa
          const Icon(
            Icons.search,
            color: Colors.white,
            size: 24,
          ),
          
          const SizedBox(width: 16),
          
          // Título
          const Expanded(
            child: Text(
              'MatchDay',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (invProvider.fulbitosData.pendingFulbitos.isNotEmpty)
                _buildCenteredDividerTitle('Invitaciones a Fulbitos'),
              ...invProvider.fulbitosData.pendingFulbitos.map((f) => _FulbitoItem(
                    fulbito: f,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        _CircleIcon(color: Color(0xFF10B981), icon: Icons.check),
                        SizedBox(width: 8),
                        _CircleIcon(color: Color(0xFFEF4444), icon: Icons.close),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              if (invProvider.fulbitosData.myFulbitos.isNotEmpty ||
                  invProvider.fulbitosData.acceptFulbitos.isNotEmpty)
                _buildCenteredDividerTitle('Mis Fulbitos'),
              ...[
                ...invProvider.fulbitosData.myFulbitos,
                ...invProvider.fulbitosData.acceptFulbitos,
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (invProvider.networkData.invitationPending.isNotEmpty)
                _buildSectionTitle('Invitaciones'),
              ...invProvider.networkData.invitationPending.map((u) => _InvitationItem(
                    username: u.username,
                    phone: u.phone,
                    photoUrl: u.photoUrl,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        _CircleIcon(color: Color(0xFF10B981), icon: Icons.check),
                        SizedBox(width: 8),
                        _CircleIcon(color: Color(0xFFEF4444), icon: Icons.close),
                      ],
                    ),
                  )),

              if (invProvider.networkData.network.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Tu red'),
                ...invProvider.networkData.network.map((u) => _InvitationItem(
                      username: u.username,
                      phone: u.phone,
                      photoUrl: u.photoUrl,
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
        // Aquí más adelante decidimos la acción según la pestaña activa.
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

class _InvitationItem extends StatelessWidget {
  final String username;
  final String phone;
  final String? photoUrl;
  final Widget trailing;

  const _InvitationItem({
    required this.username,
    required this.phone,
    required this.photoUrl,
    required this.trailing,
  });

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
            child: photoUrl != null && photoUrl!.isNotEmpty
                ? Image.network(photoUrl!, fit: BoxFit.cover)
                : const Icon(Icons.person, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
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
    );
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

class _FulbitoItem extends StatelessWidget {
  final Fulbito fulbito;
  final Widget trailing;

  const _FulbitoItem({
    required this.fulbito,
    required this.trailing,
  });

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
                child: fulbito.ownerPhotoUrl != null && fulbito.ownerPhotoUrl!.isNotEmpty
                    ? Image.network(fulbito.ownerPhotoUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.person, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fulbito.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fulbito.ownerName,
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
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  fulbito.place,
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
                '${_formatDay(fulbito.day)} ${_formatTime(fulbito.hour)}',
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
}