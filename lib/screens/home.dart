import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart' as auth_provider;
import '../providers/profile.dart';
import '../providers/invitations.dart';
import '../providers/home.dart';
import '../providers/fulbito/fulbito_provider.dart';
import '../providers/fulbito/invite_players_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/maintenance_modal.dart';
import 'vote_player_screen.dart';
import 'create_fulbito.dart';
import 'invite_player.dart';
import 'fulbito/fulbito_details.dart';
import 'invite_guest_player_screen.dart';
import '../providers/unregister_guest.dart';
import 'components/home_header.dart';
import 'tabs/fulbitos_tab.dart';
import 'tabs/network_tab.dart';

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
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      
      // Asegurar wiring con SyncProvider (por si Home se abre sin pasar por Splash)
      invitationsProvider.setSyncProvider(syncProvider);
      
      // Configurar FulbitoProvider con SyncProvider
      final fulbitoProvider = Provider.of<FulbitoProvider>(context, listen: false);
      fulbitoProvider.setSyncProvider(syncProvider);
      
      // Configurar InvitePlayersProvider con SyncProvider
      final invitePlayersProvider = Provider.of<InvitePlayersProvider>(context, listen: false);
      invitePlayersProvider.setSyncProvider(syncProvider);
      
      if (authProvider.token != null) {
        profileProvider.loadProfile(authProvider.token!);
        
        // Hacer sincronización al entrar al Home
        await _performSyncOnHomeReturn(authProvider.token!, syncProvider);
        
        await invitationsProvider.load(authProvider.token!);
        _updateNextEventFromProvider();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _refreshTimer?.cancel();
    _nextEventTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _syncOnReturn();
    }
  }

  /// Sincronización al volver de otras pantallas
  Future<void> _performSyncOnHomeReturn(String token, SyncProvider syncProvider) async {
    try {
      print('🔄 [HomeScreen] Performing sync on home return...');
      
      // Si no hay lastSync, realizar inicial; si lo hay, incremental
      if (syncProvider.lastSyncTimestamp == null) {
        print('ℹ️ [HomeScreen] No previous sync data, performing initial sync');
        await syncProvider.performInitialSync(token);
      } else {
        final success = await syncProvider.performIncrementalSync(token);
        if (success) {
          print('✅ [HomeScreen] Sync completed successfully');
        } else {
          print('⚠️ [HomeScreen] Sync failed or no changes detected');
        }
      }
    } catch (e) {
      print('❌ [HomeScreen] Error during sync: $e');
    }
  }

  /// Sincronizar al volver de otras pantallas
  Future<void> _syncOnReturn() async {
    try {
      final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      
      if (authProvider.token != null) {
        print('🔄 [HomeScreen] Syncing on return from other screen...');
        await _performSyncOnHomeReturn(authProvider.token!, syncProvider);
      }
    } catch (e) {
      print('❌ [HomeScreen] Error syncing on return: $e');
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
              // Header
              HomeHeader(onSyncReturn: _syncOnReturn),
              
              // Tabs
              _buildTabBar(),
              
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    FulbitosTab(),
                    NetworkTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF059669),
        unselectedLabelColor: const Color(0xFF6B7280),
        indicatorColor: const Color(0xFF059669),
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.sports_soccer, size: 24),
            text: 'Fulbitos',
          ),
          Tab(
            icon: Icon(Icons.group, size: 24),
            text: 'Jugadores',
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        return FloatingActionButton(
          onPressed: () {
            _showAddOptions(context);
          },
          backgroundColor: const Color(0xFF059669),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        );
      },
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¿Qué quieres hacer?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 24),
            _buildAddOption(
              context,
              icon: Icons.sports_soccer,
              title: 'Crear Fulbito',
              subtitle: 'Organiza un nuevo partido',
              color: const Color(0xFF059669),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateFulbitoScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildAddOption(
              context,
              icon: Icons.person_add,
              title: 'Invitar Jugador',
              subtitle: 'Agrega alguien a tu red',
              color: const Color(0xFF3B82F6),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InvitePlayerScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
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

    // Establecer cooldown de 3 segundos
    setState(() {
      _refreshCooldown = 3;
    });

    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _refreshCooldown--;
      });
      if (_refreshCooldown <= 0) {
        timer.cancel();
      }
    });
  }

  void _updateNextEventFromProvider() {
    final invitationsProvider = Provider.of<InvitationsProvider>(context, listen: false);
    final nextEventSeconds = invitationsProvider.fulbitosData.nextEvent;
    
    if (nextEventSeconds != null && nextEventSeconds > 0) {
      setState(() {
        _nextEventSeconds = nextEventSeconds;
      });
      
      _nextEventTimer?.cancel();
      _nextEventTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_nextEventSeconds != null && _nextEventSeconds! > 0) {
            _nextEventSeconds = _nextEventSeconds! - 1;
          } else {
            timer.cancel();
            _nextEventSeconds = null;
          }
        });
      });
    } else {
      setState(() {
        _nextEventSeconds = null;
      });
      _nextEventTimer?.cancel();
    }
  }
}