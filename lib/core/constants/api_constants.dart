class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8081';
  
  static const String login = '/api/v1/auth/signin';
  static const String registerStudent = '/api/v1/auth/signup/student';
  static const String registerDriver = '/api/v1/auth/signup/driver';
  static const String getCurrentUser = '/api/v1/users/me';
  static const String updateStudentProfile = '/api/v1/users/me/student';
  static const String updateDriverProfile = '/api/v1/users/me/driver';
}