import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart' as auth_provider;
import '../providers/phone_input.dart' as phone_input_provider;
import 'verification.dart';

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
              
              // Country selector (deshabilitado por ahora, preparado para expansión)
              const Text(
                'País',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              // Country Dropdown (deshabilitado)
              Consumer<phone_input_provider.PhoneInputProvider>(
                builder: (context, phoneProvider, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100], // Fondo gris para indicar deshabilitado
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: phoneProvider.selectedCountryCode,
                        isExpanded: true,
                        // Deshabilitado por ahora, cambiar a null para habilitar
                        onChanged: null, // phoneProvider.setCountryCode,
                        items: phoneProvider.countries.map((country) {
                          return DropdownMenuItem<String>(
                            value: country['code'],
                            child: Row(
                              children: [
                                Text(country['flag']!, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 12),
                                Text(
                                  country['name']!,
                                  style: TextStyle(
                                    color: country['code'] == phoneProvider.selectedCountryCode
                                        ? Colors.black87
                                        : Colors.grey[600],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  country['code']!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Province selector (solo para Argentina)
              Consumer<phone_input_provider.PhoneInputProvider>(
                builder: (context, phoneProvider, child) {
                  if (!phoneProvider.shouldShowProvinces) {
                    return const SizedBox.shrink(); // No mostrar si no es Argentina
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Provincia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Province Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: phoneProvider.selectedProvinceCode.isEmpty 
                                ? '' 
                                : phoneProvider.selectedProvinceCode,
                            isExpanded: true,
                            hint: const Text('Seleccionar provincia'),
                            items: phoneProvider.provinces.map((province) {
                              return DropdownMenuItem<String>(
                                value: province['code'],
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        province['name']!,
                                        style: TextStyle(
                                          color: province['code']!.isEmpty 
                                              ? Colors.grey[600] 
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (province['code']!.isNotEmpty)
                                      Text(
                                        '9${province['code']}',
                                        style: TextStyle(
                                          color: Colors.blue[600],
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                phoneProvider.setProvince(value);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Phone input
              const Text(
                'Número de teléfono sin el 15',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              // Phone Input Row
              Consumer<phone_input_provider.PhoneInputProvider>(
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
                          controller: TextEditingController(text: phoneProvider.phoneNumber)
                            ..selection = TextSelection.fromPosition(
                              TextPosition(offset: phoneProvider.phoneNumber.length),
                            ),
                          decoration: InputDecoration(
                            hintText: phoneProvider.isArgentina
                                ? (phoneProvider.selectedProvinceCode.isEmpty 
                                    ? 'Selecciona una provincia primero'
                                    : '9${phoneProvider.selectedProvinceCode}1234567')
                                : '123456789',
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
                            helperText: phoneProvider.isArgentina && phoneProvider.selectedProvinceCode.isNotEmpty 
                                ? 'Puedes editar el código de área si es necesario'
                                : null,
                            helperStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const Spacer(),
              
              // Send button
              Consumer2<auth_provider.AuthProvider, phone_input_provider.PhoneInputProvider>(
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
    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final phoneProvider = Provider.of<phone_input_provider.PhoneInputProvider>(context, listen: false);
    
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