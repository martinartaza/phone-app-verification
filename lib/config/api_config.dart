class ApiConfig {
  static const String baseUrl = 'http://192.168.100.150:8000';
  
  // API Endpoints
  static const String createUserEndpoint = '/api/auth/create-user/';
  static const String verifyUserEndpoint = '/api/auth/verify-user/';
  
  // Full URLs
  static String get createUserUrl => '$baseUrl$createUserEndpoint';
  static String get verifyUserUrl => '$baseUrl$verifyUserEndpoint';
}