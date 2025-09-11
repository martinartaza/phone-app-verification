class ApiConfig {
  // Development configuration for Flutter simulator/emulator
  // Use your machine's local IP address instead of custom domain
  static const String baseUrl = 'http://192.168.100.150:8000';
  
  // Alternative configurations:
  // For production: 'https://your-production-domain.com'
  // For local host access: 'http://app.django.com:8000' (only works on host machine)
  // For Android emulator: 'http://10.0.2.2:8000' (maps to host's localhost)
  // For iOS simulator: 'http://localhost:8000' or 'http://127.0.0.1:8000'
  
  // API Endpoints
  static const String createUserEndpoint = '/api/auth/request-code/';
  static const String verifyUserEndpoint = '/api/auth/verify-user/';
  static const String refreshTokenEndpoint = '/api/auth/refresh-token/';
  
  // Full URLs
  static String get createUserUrl => '$baseUrl$createUserEndpoint';
  static String get verifyUserUrl => '$baseUrl$verifyUserEndpoint';
  static String get refreshTokenUrl => '$baseUrl$refreshTokenEndpoint';
}