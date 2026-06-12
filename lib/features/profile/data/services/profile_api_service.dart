import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';

class ProfileApiService {
  final Dio _dio;
  ProfileApiService(this._dio);

  Future<Response> getCurrentUser() async {
    return await _dio.get(ApiConstants.getCurrentUser); 
  }
}