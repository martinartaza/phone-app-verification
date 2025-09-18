import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth.dart' as auth_provider;
import '../providers/invitations.dart';
import '../services/invite_player.dart';
import '../config/api_config.dart';

class InvitePlayerScreen extends StatefulWidget {
  const InvitePlayerScreen({Key? key}) : super(key: key);

  @override
  State<InvitePlayerScreen> createState() => _InvitePlayerScreenState();
}

class _InvitePlayerScreenState extends State<InvitePlayerScreen> {
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+5493814437123'; // Ejemplo como solicitaste
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Invitar Jugador',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            _buildPhoneInput(),
            const SizedBox(height: 20),
            _buildMessageInput(),
            const SizedBox(height: 30),
            _buildInviteButton(),
            if (_error != null) ...[
              const SizedBox(height: 20),
              _buildErrorWidget(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.person_add,
            color: Color(0xFF10B981),
            size: 30,
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invitar a tu Red',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Invita jugadores a formar parte de tu red',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Número de Teléfono',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
          ],
          style: const TextStyle(color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: 'Ejemplo: +5493814437123',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            prefixIcon: const Icon(Icons.phone, color: Color(0xFF10B981)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mensaje de Invitación',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          maxLines: 3,
          style: const TextStyle(color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: 'Escribe un mensaje personalizado...',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            prefixIcon: const Icon(Icons.message, color: Color(0xFF10B981)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInviteButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendInvitation,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Enviar Invitación',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }

  String _cleanPhoneNumber(String phoneNumber) {
    // Remover espacios, guiones, paréntesis y otros caracteres no numéricos excepto +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Si no tiene +, agregarlo
    if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }
    
    return cleaned;
  }

  Future<void> _sendInvitation() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _error = 'Por favor ingresa un número de teléfono';
      });
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      setState(() {
        _error = 'Por favor ingresa un mensaje';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'No se encontró el token de autenticación';
      });
      return;
    }

    // Limpiar el número de teléfono antes de enviarlo
    final cleanedPhoneNumber = _cleanPhoneNumber(_phoneController.text.trim());

    final result = await InvitePlayerService.invitePlayer(
      token: token,
      phoneNumber: cleanedPhoneNumber,
      message: _messageController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Recargar los datos de invitaciones
        final invitationsProvider = Provider.of<InvitationsProvider>(context, listen: false);
        await invitationsProvider.load(token);

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitación enviada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Si debe abrir WhatsApp
        if (result['shouldOpenWhatsApp']) {
          await _openWhatsApp(cleanedPhoneNumber, _messageController.text.trim());
        }

        // Volver al home
        Navigator.pop(context);
      } else {
        setState(() {
          _error = result['error'];
        });
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, String message) async {
    final whatsappMessage = '$message - ${ApiConfig.whatsappMessage}';
    
    // El número ya viene limpio desde _sendInvitation, pero por seguridad lo limpiamos de nuevo
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Remover el + para la URL de WhatsApp
    if (cleanPhone.startsWith('+')) {
      cleanPhone = cleanPhone.substring(1);
    }
    
    final whatsappUrl = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(whatsappMessage)}';
    
    try {
      final uri = Uri.parse(whatsappUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: intentar abrir WhatsApp Web
        final webUrl = 'https://web.whatsapp.com/send?phone=$cleanPhone&text=${Uri.encodeComponent(whatsappMessage)}';
        final webUri = Uri.parse(webUrl);
        
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        } else {
          // Si no puede abrir WhatsApp, mostrar un mensaje con el número y mensaje
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No se pudo abrir WhatsApp. Número: +$cleanPhone'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
