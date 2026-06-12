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
    String base64Image = "foto_simulada_para_tb2.jpg";

    Map<String, dynamic> payload = {
      "username": dto.username,
      "firstName": dto.firstName,
      "lastName": dto.lastName,
      "email": dto.email,
      "password": dto.password,
      "phoneNumber": dto.phoneNumber,
      "universityName": dto.universityName,
      "tiuPhoto": base64Image, 
    };

    return await _dio.post(
      ApiConstants.registerStudent, 
      data: payload,
    );
  }

  Future<Response> registerDriver(DriverSignUpDto dto) async {
    return await _dio.post(ApiConstants.registerDriver, data: dto.toJson());
  }
}