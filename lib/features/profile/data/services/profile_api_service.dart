import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/update_student_profile_request_dto.dart';
import '../models/update_driver_profile_request_dto.dart';

class ProfileApiService {
  final Dio _dio;
  ProfileApiService(this._dio);

  Future<Response> getCurrentUser() async {
    // El header Authorization se inyecta automáticamente vía JwtInterceptor
    return await _dio.get(ApiConstants.getCurrentUser); 
  }

  Future<Response> updateStudentProfile(UpdateStudentProfileRequestDto dto) async {
    return await _dio.put(
      ApiConstants.updateStudentProfile,
      data: dto.toJson(),
    );
  }

  Future<Response> updateDriverProfile(UpdateDriverProfileRequestDto dto) async {
    return await _dio.put(
      ApiConstants.updateDriverProfile,
      data: dto.toJson(),
    );
  }
}
