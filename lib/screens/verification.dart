import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart' as auth_provider;
import '../providers/verification.dart' as verification_provider;
import 'home.dart';

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const VerificationScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void initState() {
    super.initState();
    // Iniciar el timer cuando se carga la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<verification_provider.VerificationProvider>(context, listen: false).startResendTimer();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Auto verificar cuando todos los campos están llenos
    final verificationProvider = Provider.of<verification_provider.VerificationProvider>(context, listen: false);
    final codeDigits = _controllers.map((controller) => controller.text).toList();
    
    if (verificationProvider.isCodeComplete(codeDigits)) {
      _verifyCode();
    }
  }

  Future<void> _verifyCode() async {
    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final verificationProvider = Provider.of<verification_provider.VerificationProvider>(context, listen: false);
    
    final codeDigits = _controllers.map((controller) => controller.text).toList();
    final code = verificationProvider.getCodeAsString(codeDigits);
    
    if (!verificationProvider.isCodeComplete(codeDigits)) {
      _showMessage('Por favor ingresa el código completo', isError: true);
      return;
    }

    verificationProvider.setVerifying(true);
    
    final success = await authProvider.verifyCode(widget.phoneNumber, code);
    
    verificationProvider.setVerifying(false);

    if (success && mounted) {
      _showMessage('✅ Verificación exitosa', isError: false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (mounted) {
      // Limpiar campos en caso de error
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      
      final errorMessage = authProvider.errorMessage ?? 'Código incorrecto. Intenta nuevamente.';
      _showMessage(errorMessage, isError: true);
    }
  }

  Future<void> _resendCode() async {
    final verificationProvider = Provider.of<verification_provider.VerificationProvider>(context, listen: false);
    
    final success = await verificationProvider.resendCode(widget.phoneNumber);
    
    if (success && mounted) {
      _showMessage('Código reenviado', isError: false);
    } else if (mounted) {
      _showMessage('Error al reenviar código', isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.security,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Código de verificación',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              // Subtitle
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  children: [
                    const TextSpan(text: 'Hemos enviado un código de 6 dígitos a\n'),
                    TextSpan(
                      text: widget.phoneNumber,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Code input instruction
              const Text(
                'Ingresa el código recibido',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              
              // Code input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return Container(
                    width: 45,
                    height: 55,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _controllers[index].text.isNotEmpty 
                            ? Colors.green 
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onChanged: (value) => _onCodeChanged(value, index),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              
              // Verify button
              Consumer2<auth_provider.AuthProvider, verification_provider.VerificationProvider>(
                builder: (context, authProvider, verificationProvider, child) {
                  final isLoading = authProvider.isLoading || verificationProvider.isVerifying;
                  
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _verifyCode,
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
                            colors: [Colors.green, Colors.blue],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.security, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Verificar código',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, color: Colors.white),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // Resend section
              Consumer<verification_provider.VerificationProvider>(
                builder: (context, verificationProvider, child) {
                  return Column(
                    children: [
                      Text(
                        verificationProvider.canResend 
                            ? 'No recibiste el código?'
                            : 'Reenviar código en ${verificationProvider.resendTimer}s',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      if (verificationProvider.canResend)
                        TextButton(
                          onPressed: _resendCode,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh, size: 18),
                              SizedBox(width: 4),
                              Text(
                                'Reenviar código',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}