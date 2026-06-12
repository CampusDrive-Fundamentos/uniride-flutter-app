import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/student.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../services/profile_api_service.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApiService apiService;

  ProfileRepositoryImpl(this.apiService);

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final response = await apiService.getCurrentUser();
      final data = response.data;
      
      // Mapeo básico a Student (en un escenario real mapearías según el rol)
      final user = Student(
        id: data['id'] ?? 0,
        username: data['username'] ?? '',
        email: data['email'] ?? '',
        universityName: data['universityName'] ?? 'UPC',
        tiuPhotoUrl: data['tiuPhotoUrl'] ?? '',
      );
      return Right(user);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data['message'] ?? 'Error al obtener perfil'));
    }
  }
}