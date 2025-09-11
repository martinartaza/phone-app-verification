import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/phone_input_screen.dart';
import 'screens/home_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/phone_input_provider.dart';
import 'providers/verification_provider.dart';

void main() {
  runApp(const PhoneVerificationApp());
}

class PhoneVerificationApp extends StatelessWidget {
  const PhoneVerificationApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PhoneInputProvider()),
        ChangeNotifierProvider(create: (_) => VerificationProvider()),
      ],
      child: MaterialApp(
        title: 'Phone Verification',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          fontFamily: 'SF Pro Display',
        ),
        home: const SplashScreen(),
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Esperar a que termine la inicialización del AuthProvider
      while (!authProvider.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      }
      
      print('🔍 Estado de autenticación verificado:');
      print('  - isAuthenticated: ${authProvider.isAuthenticated}');
      print('  - phoneNumber: ${authProvider.phoneNumber}');
      print('  - userData: ${authProvider.userData?.username}');
      
      if (authProvider.isAuthenticated) {
        print('✅ Usuario ya autenticado, navegando al home');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        print('❌ Usuario no autenticado, navegando al login');
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
            // Logo/Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.phone_android,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            
            // App name
            const Text(
              'Phone Verification',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Loading indicator
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            
            // Loading text
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                String statusText = 'Verificando autenticación...';
                if (authProvider.isLoading) {
                  statusText = 'Cargando datos...';
                } else if (authProvider.isInitialized) {
                  statusText = authProvider.isAuthenticated 
                      ? 'Usuario autenticado ✅' 
                      : 'Redirigiendo al login...';
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