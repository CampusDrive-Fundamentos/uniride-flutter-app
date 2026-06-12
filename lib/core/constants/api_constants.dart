class ApiConstants {
  static const String baseUrl = 'https://uniride-iam-service.onrender.com';
  
  static const String login = '/api/v1/auth/signin';
  static const String registerStudent = '/api/v1/auth/signup/student';
  static const String registerDriver = '/api/v1/auth/signup/driver';
  static const String getCurrentUser = '/api/v1/users/me';
}