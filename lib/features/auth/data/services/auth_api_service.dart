import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/login_request_dto.dart';
import '../models/student_signup_dto.dart';
import '../models/driver_signup_dto.dart';

class AuthApiService {
  final Dio _dio;

  AuthApiService(this._dio);

  Future<Response> login(String email, String password) async {
    final dto = LoginRequestDto(email: email, password: password);
    return await _dio.post(ApiConstants.login, data: dto.toJson());
  }

  Future<Response> registerStudent(StudentSignUpDto dto) async {
    return await _dio.post(
      ApiConstants.registerStudent, 
      data: dto.toJson(),
    );
  }

  Future<Response> registerDriver(DriverSignUpDto dto) async {
    return await _dio.post(
      ApiConstants.registerDriver, 
      data: dto.toJson(),
    );
  }
}
