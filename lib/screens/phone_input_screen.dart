import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/phone_input_provider.dart';
import 'verification_screen.dart';

class PhoneInputScreen extends StatelessWidget {
  const PhoneInputScreen({Key? key}) : super(key: key);

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
                    colors: [Colors.blue, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.phone_android,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Verificar teléfono',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Ingresa tu número para recibir el código de verificación',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Country selector
              const Text(
                'Selecciona tu país',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              // Country Dropdown
              Consumer<PhoneInputProvider>(
                builder: (context, phoneProvider, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: phoneProvider.selectedCountryCode,
                        isExpanded: true,
                        items: phoneProvider.countries.map((country) {
                          return DropdownMenuItem<String>(
                            value: country['code'],
                            child: Row(
                              children: [
                                Text(country['flag']!, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 12),
                                Text(country['name']!),
                                const Spacer(),
                                Text(country['code']!, style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            phoneProvider.setCountryCode(value);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Phone input
              const Text(
                'Número de teléfono',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              // Phone Input Row
              Consumer<PhoneInputProvider>(
                builder: (context, phoneProvider, child) {
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          phoneProvider.selectedCountryCode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          onChanged: phoneProvider.setPhoneNumber,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: '123456789',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            errorText: phoneProvider.errorMessage,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const Spacer(),
              
              // Send button
              Consumer2<AuthProvider, PhoneInputProvider>(
                builder: (context, authProvider, phoneProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : () => _sendCode(context),
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
                          child: authProvider.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.phone, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Enviar código',
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendCode(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phoneProvider = Provider.of<PhoneInputProvider>(context, listen: false);
    
    // Validar número
    if (!phoneProvider.isPhoneNumberValid()) {
      phoneProvider.setError(phoneProvider.getValidationError() ?? 'Número inválido');
      return;
    }
    
    // Enviar código
    final success = await authProvider.sendVerificationCode(phoneProvider.fullPhoneNumber);
    
    if (success && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationScreen(phoneNumber: phoneProvider.fullPhoneNumber),
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Error al enviar el código'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}