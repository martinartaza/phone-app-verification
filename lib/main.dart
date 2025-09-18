import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/phone_input.dart';
import 'screens/home.dart';
import 'screens/profile.dart';
import 'providers/auth.dart' as auth_provider;
import 'providers/phone_input.dart' as phone_input_provider;
import 'providers/verification.dart' as verification_provider;
import 'providers/profile.dart';
import 'providers/invitations.dart';
import 'providers/home.dart';
import 'providers/fulbito/fulbito_provider.dart';
import 'providers/fulbito/invite_players_provider.dart';
import 'providers/vote.dart';
import 'screens/fulbito/invite_players.dart';

void main() {
  runApp(const MatchDayApp());
}

class MatchDayApp extends StatelessWidget {
  const MatchDayApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => auth_provider.AuthProvider()),
        ChangeNotifierProvider(create: (_) => phone_input_provider.PhoneInputProvider()),
        ChangeNotifierProvider(create: (_) => verification_provider.VerificationProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => InvitationsProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => FulbitoProvider()),
        ChangeNotifierProvider(create: (_) => InvitePlayersProvider()),
        ChangeNotifierProvider(create: (_) => VoteProvider()),
      ],
      child: MaterialApp(
        title: 'MatchDay',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          fontFamily: 'SF Pro Display',
        ),
        home: const SplashScreen(),
        routes: {
          '/phone': (context) => const PhoneInputScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/home': (context) => const HomeScreen(),
          '/fulbito/invite-players': (context) => const InvitePlayersScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Pequeña pausa para mostrar el splash
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      
      // Esperar a que termine la inicialización del AuthProvider
      while (!authProvider.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      }
      
      if (authProvider.isAuthenticated) {
        // Verificar si tiene perfil completo
        if (authProvider.token != null) {
          await profileProvider.loadProfile(authProvider.token!);
        }
        
        // Si tiene perfil completo, ir al home, sino al perfil
        final hasProfile = profileProvider.profile.name.isNotEmpty;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => hasProfile ? const HomeScreen() : const ProfileScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PhoneInputScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo MatchDay
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2196F3)], // Verde y azul como el logo
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sports_soccer,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            
            // App name
            const Text(
              'MatchDay',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            const Text(
              'Organiza tu fulbito semanal',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            // Loading indicator
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            
            // Loading text
            Consumer<auth_provider.AuthProvider>(
              builder: (context, authProvider, child) {
                String statusText = 'Verificando datos locales...';
                if (authProvider.isLoading) {
                  statusText = 'Verificando con el servidor...';
                } else if (authProvider.isInitialized) {
                  statusText = authProvider.isAuthenticated 
                      ? 'Sesión válida, ir al Home ✅' 
                      : 'Sin sesión válida, ir al login...';
                }
                
                return Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}