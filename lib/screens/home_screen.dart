import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'phone_input_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Verificar y renovar tokens al cargar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTokensAndRefreshData();
    });
  }

  Future<void> _checkTokensAndRefreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    print('🏠 Home cargado, verificando con servidor...');
    
    // SIEMPRE verificar con el servidor usando datos guardados
    final serverResponse = await authProvider.verifyWithServer();
    
    if (!serverResponse && mounted) {
      // El servidor rechazó los datos, ir al login
      print('❌ Servidor rechazó verificación, ir al login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Sesión expirada, por favor inicia sesión nuevamente'),
          backgroundColor: Colors.orange,
        ),
      );
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PhoneInputScreen()),
        (route) => false,
      );
      return;
    }
    
    print('✅ Servidor confirmó validez, refrescando datos');
    // Refrescar datos del usuario
    await authProvider.refreshUserData();
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const PhoneInputScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showStoredData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final allData = await authProvider.getStoredData();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Datos Almacenados'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('📱 Teléfono: ${allData['phone_number'] ?? 'No guardado'}'),
                  const SizedBox(height: 8),
                  Text('🔢 Código: ${allData['verification_code'] ?? 'No guardado'}'),
                  const SizedBox(height: 8),
                  Text('🔐 Token: ${allData['access_token'] != null ? '${allData['access_token'].toString().substring(0, 20)}...' : 'No guardado'}'),
                  const SizedBox(height: 8),
                  Text('🔄 Refresh Token: ${allData['refresh_token'] != null ? '${allData['refresh_token'].toString().substring(0, 20)}...' : 'No guardado'}'),
                  const SizedBox(height: 8),
                  Text('✅ Logueado: ${allData['is_logged_in'] ?? false}'),
                  const SizedBox(height: 8),
                  const Text('💡 Refresh token válido por 10 días'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _renewTokens() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔄 Renovando tokens...')),
    );
    
    final success = await authProvider.checkAndRenewTokens();
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tokens renovados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error renovando tokens'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Si falló la renovación, ir al login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PhoneInputScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // Success icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        colors: [Colors.green, Colors.blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Welcome title
                  const Text(
                    '¡Bienvenido!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // User info
                  if (authProvider.userData != null)
                    Text(
                      authProvider.userData!.username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Success message
                  Text(
                    'Tu número de teléfono ha sido verificado exitosamente',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  
                  // Feature cards
                  Expanded(
                    child: ListView(
                      children: [
                        _buildFeatureCard(
                          icon: Icons.security,
                          title: 'Cuenta Verificada',
                          description: 'Tu cuenta está completamente verificada y segura',
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureCard(
                          icon: Icons.phone,
                          title: 'Teléfono: ${authProvider.phoneNumber ?? 'No disponible'}',
                          description: 'Número de teléfono verificado',
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureCard(
                          icon: Icons.token,
                          title: 'Tokens Activos',
                          description: 'Access token y refresh token guardados (10 días)',
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureCard(
                          icon: Icons.storage,
                          title: 'Ver Datos Guardados',
                          description: 'Toca para ver todos los datos almacenados',
                          color: Colors.orange,
                          onTap: _showStoredData,
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureCard(
                          icon: Icons.refresh,
                          title: 'Renovar Tokens',
                          description: 'Toca para renovar tokens manualmente',
                          color: Colors.teal,
                          onTap: _renewTokens,
                        ),
                      ],
                    ),
                  ),
                  
                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.red, Colors.orange],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Cerrar Sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
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
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}