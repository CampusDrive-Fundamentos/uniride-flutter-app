import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/student.dart';
import '../../../auth/domain/entities/driver.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/user_profile_response_dto.dart';
import '../models/update_student_profile_request_dto.dart';
import '../models/update_driver_profile_request_dto.dart';
import '../../../auth/data/models/vehicle_dto.dart';
import '../services/profile_api_service.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApiService apiService;

  ProfileRepositoryImpl(this.apiService);

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final response = await apiService.getCurrentUser();
      final dto = UserProfileResponseDto.fromJson(response.data);
      return Right(_mapDtoToEntity(dto));
    } on DioException catch (e) {
      return Left(ServerFailure(_extractMessage(e)));
    } catch (e) {
      return const Left(ServerFailure('Error inesperado al obtener perfil.'));
    }
  }

  @override
  Future<Either<Failure, User>> updateStudentProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      final dto = UpdateStudentProfileRequestDto(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      final response = await apiService.updateStudentProfile(dto);
      final responseDto = UserProfileResponseDto.fromJson(response.data);
      return Right(_mapDtoToEntity(responseDto));
    } on DioException catch (e) {
      return Left(ServerFailure(_extractMessage(e)));
    } catch (e) {
      return const Left(ServerFailure('Error al actualizar perfil de estudiante.'));
    }
  }

  @override
  Future<Either<Failure, User>> updateDriverProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String cardNumber,
    required String vehicleType,
    required String vehicleName,
    required String vehiclePlate,
  }) async {
    try {
      final dto = UpdateDriverProfileRequestDto(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        cardNumber: cardNumber,
        vehicle: VehicleDto(
          type: vehicleType,
          name: vehicleName,
          licenseNumber: vehiclePlate,
        ),
      );
      final response = await apiService.updateDriverProfile(dto);
      final responseDto = UserProfileResponseDto.fromJson(response.data);
      return Right(_mapDtoToEntity(responseDto));
    } on DioException catch (e) {
      return Left(ServerFailure(_extractMessage(e)));
    } catch (e) {
      return const Left(ServerFailure('Error al actualizar perfil de conductor.'));
    }
  }

  User _mapDtoToEntity(UserProfileResponseDto dto) {
    if (dto.role == 'DRIVER') {
      return Driver(
        id: 0,
        firstName: dto.firstName,
        lastName: dto.lastName,
        username: dto.email.split('@')[0],
        email: dto.email,
        phoneNumber: dto.phoneNumber,
        role: dto.role,
        dni: '', // No disponible en este endpoint
        licenseNumber: '', // No disponible en este endpoint
        cardNumber: dto.cardNumber,
        vehicle: dto.vehicle != null ? VehicleEntity(
          type: dto.vehicle!.type,
          name: dto.vehicle!.name,
          licenseNumber: dto.vehicle!.licenseNumber,
        ) : null,
      );
    } else {
      return Student(
        id: 0,
        firstName: dto.firstName,
        lastName: dto.lastName,
        username: dto.email.split('@')[0],
        email: dto.email,
        phoneNumber: dto.phoneNumber,
        role: dto.role,
        universityName: 'UPC',
        tiuPhotoUrl: '',
        cardNumber: dto.cardNumber,
        vehicle: dto.vehicle != null ? VehicleEntity(
          type: dto.vehicle!.type,
          name: dto.vehicle!.name,
          licenseNumber: dto.vehicle!.licenseNumber,
        ) : null,
      );
    }
  }

  String _extractMessage(DioException e) {
    if (e.response?.data != null && e.response?.data is Map) {
      return e.response?.data['message'] ?? 'Error del servidor.';
    }
    return 'Error al conectar con el servidor.';
  }
}
