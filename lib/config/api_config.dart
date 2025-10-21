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
    //return 'http://192.168.100.150:8000';
    return 'https://django.sebastianartaza.com';
  }
  //static const String baseUrl = 'http://192.168.100.150:8000';
  // Configuraciones manuales para override si es necesario:
  // static const String baseUrl = 'http://192.168.100.150:8000';  // IP local
  // static const String baseUrl = 'http://10.0.2.2:8000';         // Android Emulator
  // static const String baseUrl = 'http://localhost:8000';        // iOS Simulator
  
  // API Endpoints
  static const String createUserEndpoint = '/api/v2/auth/request-code/';
  static const String verifyUserEndpoint = '/api/v2/auth/verify/';
  static const String refreshTokenEndpoint = '/api/v2/auth/refresh-token/';
  static const String getProfileEndpoint = '/api/v2/user/profile/';
  static const String updateProfileEndpoint = '/api/v2/user/profile/update/';
  static const String syncInitialEndpoint = '/api/v2/sync/initial/';
  static const String syncEndpoint = '/api/v2/sync/';
  static const String invitationsEndpoint = '/api/v2/network/connections/';
  static const String votePlayerEndpoint = '/api/auth/players/';
  static const String getPlayerDetailsEndpoint = '/api/auth/players/';
  static const String setPlayerOpinionEndpoint = '/api/auth/players/';
  static const String createFulbitoEndpoint = '/api/v2/fulbito/create/';
  static const String updateFulbitoEndpoint = '/api/v2/fulbito/';
  static const String deleteFulbitoEndpoint = '/api/v2/fulbito/';
  static const String invitePlayerEndpoint = '/api/v2/network/invite/';
  static const String acceptConnectionEndpoint = '/api/v2/network/connection/';
  static const String rejectConnectionEndpoint = '/api/v2/network/connection/';
  static const String invitationStatusEndpoint = '/api/auth/invitation/network/';
  static const String fulbitoStatusEndpoint = '/api/auth/invitation/fulbito/';
  static const String fulbitoPlayersEndpoint = '/api/auth/fulbito/';
  static const String fulbitoInviteEndpoint = '/api/v2/fulbito/';
  static const String fulbitoInviteListEndpoint = '/api/v2/fulbito/';
  static const String fulbitoDetailsEndpoint = '/api/v2/fulbito/';
  static const String fulbitoRegisterEndpoint = '/api/v2/fulbito/';
  static const String fulbitoRegisterInviteEndpoint = '/api/v2/fulbito/';
  static const String fulbitoUnregisterEndpoint = '/api/v2/fulbito/';
  static const String fulbitoUnregisterInviteEndpoint = '/api/v2/fulbito/';
  
  // Full URLs
  static String get createUserUrl => '$baseUrl$createUserEndpoint';
  static String get verifyUserUrl => '$baseUrl$verifyUserEndpoint';
  static String get refreshTokenUrl => '$baseUrl$refreshTokenEndpoint';
  static String get getProfileUrl => '$baseUrl$getProfileEndpoint';
  static String get updateProfileUrl => '$baseUrl$updateProfileEndpoint';
  static String getSyncInitialUrl(int nextPage) => '$baseUrl$syncInitialEndpoint?next_page=$nextPage';
  static String getSyncUrl([String? lastSync]) => lastSync != null 
      ? '$baseUrl$syncEndpoint?last_sync=$lastSync'
      : '$baseUrl$syncEndpoint';
  static String get invitationsUrl => '$baseUrl$invitationsEndpoint';
  static String getVotePlayerUrl(String uuid) => '$baseUrl$votePlayerEndpoint$uuid/opinion/';
  static String getPlayerDetailsUrl(String uuid) => '$baseUrl$getPlayerDetailsEndpoint$uuid/opinion/';
  static String setPlayerOpinionUrl(String uuid) => '$baseUrl$setPlayerOpinionEndpoint$uuid/opinion/set/';
  static String get createFulbitoUrl => '$baseUrl$createFulbitoEndpoint';
  static String getUpdateFulbitoUrl(int fulbitoId) => '$baseUrl$updateFulbitoEndpoint$fulbitoId/update/';
  static String getDeleteFulbitoUrl(int fulbitoId) => '$baseUrl$deleteFulbitoEndpoint$fulbitoId/delete/';
  static String get invitePlayerUrl => '$baseUrl$invitePlayerEndpoint';
  static String getAcceptConnectionUrl(int connectionId) => '$baseUrl$acceptConnectionEndpoint$connectionId/accept/';
  static String getRejectConnectionUrl(int connectionId) => '$baseUrl$rejectConnectionEndpoint$connectionId/reject/';
  static String getInvitationStatusUrl(int invitationId) => '$baseUrl$invitationStatusEndpoint$invitationId/status/';
  static String getFulbitoStatusUrl(int invitationId) => '$baseUrl$fulbitoStatusEndpoint$invitationId/status/';
  static String getFulbitoPlayersUrl(int fulbitoId) => '$baseUrl$fulbitoPlayersEndpoint$fulbitoId/players';
  static String getFulbitoInviteUrl(int fulbitoId) => '$baseUrl$fulbitoInviteEndpoint$fulbitoId/invite/';
  static String getFulbitoInviteListUrl(int fulbitoId) => '$baseUrl$fulbitoInviteListEndpoint$fulbitoId/invite/list/';
  static String getFulbitoDetailsUrl(int fulbitoId) => '$baseUrl$fulbitoDetailsEndpoint$fulbitoId/details/';
  static String getFulbitoRegisterUrl(int fulbitoId) => '$baseUrl$fulbitoRegisterEndpoint$fulbitoId/register/';
  static String getFulbitoRegisterInviteUrl(int fulbitoId) => '$baseUrl$fulbitoRegisterInviteEndpoint$fulbitoId/register_invite/';
  static String getFulbitoUnregisterUrl(int fulbitoId) => '$baseUrl$fulbitoUnregisterEndpoint$fulbitoId/unregister/';
  static String getFulbitoUnregisterInviteUrl(int fulbitoId) => '$baseUrl$fulbitoUnregisterInviteEndpoint$fulbitoId/unregister_invite/';
  static String getFulbitoTeamsUrl(int fulbitoId) => '$baseUrl/api/auth/fulbito/$fulbitoId/teams/';
  
  // WhatsApp message configuration
  static const String whatsappMessage = 'Descarga fulbito de la playstore';
  
  // Maintenance message configuration
  static const String maintenanceTitle = '🔧 Mantenimiento Programado';
  static const String maintenanceMessage = 'Estamos actualizando la aplicación para mejorar tu experiencia. Por favor, intenta nuevamente en unos minutos.';
  static const String retryButtonText = 'Reintentar';
  static const String laterButtonText = 'Más tarde';
  
  // Registration messages configuration
  static const String registrationSuccessTitle = '¡Inscripción Exitosa!';
  static const String registrationSuccessMessage = 'Te has inscrito correctamente en el fulbito.';
  static const String registrationSubstituteTitle = '¡Te inscribiste como Suplente!';
  static const String registrationSubstituteMessage = 'El fulbito está completo, pero te agregamos como suplente.';
  static const String registrationErrorTitle = 'Error en la Inscripción';
  static const String registrationErrorMessage = 'No se pudo completar la inscripción. Intenta nuevamente.';
}