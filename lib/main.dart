import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/phone_input.dart';
import 'screens/home.dart';
import 'providers/auth.dart' as auth_provider;
import 'providers/phone_input.dart' as phone_input_provider;
import 'providers/verification.dart' as verification_provider;

void main() {
  runApp(const PhoneVerificationApp());
}

class PhoneVerificationApp extends StatelessWidget {
  const PhoneVerificationApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => auth_provider.AuthProvider()),
        ChangeNotifierProvider(create: (_) => phone_input_provider.PhoneInputProvider()),
        ChangeNotifierProvider(create: (_) => verification_provider.VerificationProvider()),
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
      final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
      
      // Esperar a que termine la inicialización del AuthProvider
      while (!authProvider.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      }
      
      if (authProvider.isAuthenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
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
            Consumer<auth_provider.AuthProvider>(
              builder: (context, authProvider, child) {
                String statusText = 'Verificando datos locales...';
                if (authProvider.isLoading) {
                  statusText = 'Cargando datos guardados...';
                } else if (authProvider.isInitialized) {
                  statusText = authProvider.isAuthenticated 
                      ? 'Datos encontrados, ir al Home ✅' 
                      : 'Sin datos, ir al login...';
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