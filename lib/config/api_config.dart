import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Configuración automática según la plataforma
  static String get baseUrl {
    if (kIsWeb) {
      // Flutter Web - usar IP local
      return 'http://192.168.100.150:8000';
    } else if (Platform.isAndroid) {
      // Android Emulator - usar IP especial que mapea a localhost del host
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // iOS Simulator - usar localhost
      return 'http://localhost:8000';
    } else {
      // Desktop (macOS, Windows, Linux) - usar IP local
      return 'http://192.168.100.150:8000';
    }
  }
  
  // Configuraciones manuales para override si es necesario:
  // static const String baseUrl = 'http://192.168.100.150:8000';  // IP local
  // static const String baseUrl = 'http://10.0.2.2:8000';         // Android Emulator
  // static const String baseUrl = 'http://localhost:8000';        // iOS Simulator
  
  // API Endpoints
  static const String createUserEndpoint = '/api/auth/request-code/';
  static const String verifyUserEndpoint = '/api/auth/verify-user/';
  static const String refreshTokenEndpoint = '/api/auth/refresh-token/';
  
  // Full URLs
  static String get createUserUrl => '$baseUrl$createUserEndpoint';
  static String get verifyUserUrl => '$baseUrl$verifyUserEndpoint';
  static String get refreshTokenUrl => '$baseUrl$refreshTokenEndpoint';
}