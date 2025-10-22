import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth.dart' as auth_provider;
import '../../providers/profile.dart';
import '../../providers/home.dart';
import '../../providers/invitations.dart';
import '../../providers/sync_provider.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback? onSyncReturn;

  const HomeHeader({
    Key? key,
    this.onSyncReturn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          
          // Botón de sincronización manual
          Consumer<SyncProvider>(
            builder: (context, syncProvider, child) {
              return GestureDetector(
                onTap: () async {
                  final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
                  final token = authProvider.token;
                  
                  if (token != null) {
                    print('🔄 [HomeHeader] Iniciando sincronización completa...');
                    await syncProvider.forceFullSync(token);
                    print('✅ [HomeHeader] Sincronización completa finalizada');
                  } else {
                    print('❌ [HomeHeader] No hay token disponible para sincronización');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: No hay sesión activa'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                  ),
                  child: syncProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.sync,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              );
            },
          ),
          
          const SizedBox(width: 12),
          
          // Foto de perfil
          Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) {
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/profile').then((_) {
                    // Sincronizar al volver del perfil
                    onSyncReturn?.call();
                  });
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
          
          const SizedBox(width: 12),
          
          // Botón de cerrar sesión
          GestureDetector(
            onTap: () async {
              print('🚪 [HomeHeader] Cerrando sesión...');
              
              // Limpiar datos de autenticación
              final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
              await authProvider.logout();
              
              // Limpiar datos de sync
              final syncProvider = Provider.of<SyncProvider>(context, listen: false);
              await syncProvider.clearSyncState();
              
              print('✅ [HomeHeader] Sesión cerrada, redirigiendo a phone_input');
              
              // Navegar a phone_input y limpiar stack
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
