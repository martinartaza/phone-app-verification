import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import 'home_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const VerificationScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 55;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _resendCode() async {
    if (_resendTimer > 0) return;
    
    final success = await AuthService.createUser(widget.phoneNumber);
    if (success) {
      setState(() {
        _resendTimer = 55;
      });
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Código reenviado')),
      );
    }
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Auto verify when all fields are filled
    if (_controllers.every((controller) => controller.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  Future<void> _verifyCode() async {
    String code = _controllers.map((controller) => controller.text).join();
    
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor ingresa el código completo')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await AuthService.verifyUser(widget.phoneNumber, code);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // Clear the code fields
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Código incorrecto. Intenta nuevamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: [
              Spacer(),
              
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.security,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              SizedBox(height: 32),
              
              // Title
              Text(
                'Código de verificación',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              
              // Subtitle
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  children: [
                    TextSpan(text: 'Hemos enviado un código de 6 dígitos a\n'),
                    TextSpan(
                      text: widget.phoneNumber,
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              
              // Code input instruction
              Text(
                'Ingresa el código recibido',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 24),
              
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onChanged: (value) => _onCodeChanged(value, index),
                    ),
                  );
                }),
              ),
              SizedBox(height: 40),
              
              // Verify button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.blue],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Row(
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
              ),
              SizedBox(height: 32),
              
              // Resend section
              Text(
                _resendTimer > 0 
                    ? 'Reenviar código en ${_resendTimer}s'
                    : 'No recibiste el código?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              
              if (_resendTimer == 0)
                TextButton(
                  onPressed: _resendCode,
                  child: Row(
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
              
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}