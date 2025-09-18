import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Configuración automática según la plataforma
  static String get baseUrl {
    /*
    if (kIsWeb) {
      // Flutter Web - usar IP local
      return 'http://192.168.100.150:8000';
    } else if (Platform.isAndroid) {
      // Detectar si es emulador o dispositivo físico
      return kDebugMode 
          ? 'http://10.0.2.2:8000'           // Android Emulator (debug)
          : 'http://192.168.100.150:8000';   // Dispositivo físico (release APK)
    } else if (Platform.isIOS) {
      // iOS Simulator - usar localhost
      return 'http://localhost:8000';
    } else {
      // Desktop (macOS, Windows, Linux) - usar IP local
      return 'http://192.168.100.150:8000';
    }
    */
    return 'http://192.168.100.150:8000';
  }
  //static const String baseUrl = 'http://192.168.100.150:8000';
  // Configuraciones manuales para override si es necesario:
  // static const String baseUrl = 'http://192.168.100.150:8000';  // IP local
  // static const String baseUrl = 'http://10.0.2.2:8000';         // Android Emulator
  // static const String baseUrl = 'http://localhost:8000';        // iOS Simulator
  
  // API Endpoints
  static const String createUserEndpoint = '/api/auth/request-code/';
  static const String verifyUserEndpoint = '/api/auth/verify-user/';
  static const String refreshTokenEndpoint = '/api/auth/refresh-token/';
  static const String updateProfileEndpoint = '/api/auth/players/me/';
  static const String invitationsEndpoint = '/api/auth/invitation/all/';
  static const String votePlayerEndpoint = '/api/auth/players/';
  static const String createFulbitoEndpoint = '/api/auth/fulbito/';
  static const String invitePlayerEndpoint = '/api/auth/invitation/network/invite/';
  static const String invitationStatusEndpoint = '/api/auth/invitation/network/';
  static const String fulbitoStatusEndpoint = '/api/auth/invitation/fulbito/';
  
  // Full URLs
  static String get createUserUrl => '$baseUrl$createUserEndpoint';
  static String get verifyUserUrl => '$baseUrl$verifyUserEndpoint';
  static String get refreshTokenUrl => '$baseUrl$refreshTokenEndpoint';
  static String get updateProfileUrl => '$baseUrl$updateProfileEndpoint';
  static String get invitationsUrl => '$baseUrl$invitationsEndpoint';
  static String getVotePlayerUrl(String uuid) => '$baseUrl$votePlayerEndpoint$uuid/opinion/';
  static String get createFulbitoUrl => '$baseUrl$createFulbitoEndpoint';
  static String get invitePlayerUrl => '$baseUrl$invitePlayerEndpoint';
  static String getInvitationStatusUrl(int invitationId) => '$baseUrl$invitationStatusEndpoint$invitationId/status/';
  static String getFulbitoStatusUrl(int invitationId) => '$baseUrl$fulbitoStatusEndpoint$invitationId/status/';
  
  // WhatsApp message configuration
  static const String whatsappMessage = 'Descarga fulbito de la playstore';
  
  // Maintenance message configuration
  static const String maintenanceTitle = '🔧 Mantenimiento Programado';
  static const String maintenanceMessage = 'Estamos actualizando la aplicación para mejorar tu experiencia. Por favor, intenta nuevamente en unos minutos.';
  static const String retryButtonText = 'Reintentar';
  static const String laterButtonText = 'Más tarde';
}