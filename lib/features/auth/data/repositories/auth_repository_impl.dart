import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/auth_api_service.dart';
import '../models/student_signup_dto.dart';
import '../models/driver_signup_dto.dart';
import '../models/vehicle_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService apiService;
  final FlutterSecureStorage secureStorage;

  AuthRepositoryImpl({required this.apiService, required this.secureStorage});

  @override
  Future<Either<Failure, String>> login(String email, String password) async {
    try {
      final response = await apiService.login(email, password);
      final token = response.data['token'];
      await secureStorage.write(key: 'jwt_token', value: token);
      return Right(token);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractMessage(e)));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado.'));
    }
  }

  @override
  Future<Either<Failure, String>> registerStudent({
    required String username, required String firstName, required String lastName,
    required String email, required String password, required String phoneNumber,
    required String universityName, required File tiuPhoto,
  }) async {
    try {
      // Nota: El contrato nuevo pide String para tiuPhoto (puede ser base64)
      final dto = StudentSignUpDto(
        firstName: firstName, 
        lastName: lastName,
        email: email, 
        password: password, 
        phoneNumber: phoneNumber,
        universityName: universityName, 
        tiuPhoto: "base64_simulated_for_contract", 
      );
      
      final response = await apiService.registerStudent(dto);
      return Right(response.data['message'] ?? 'Registro exitoso.');
    } on DioException catch (e) {
      return Left(ServerFailure(_extractMessage(e)));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado al procesar los datos.'));
    }
  }

  @override
  Future<Either<Failure, String>> registerDriver({
    required String username, required String firstName, required String lastName,
    required String email, required String password, required String phoneNumber,
    required String dni, required String licenseNumber, required String culCertificate,
    required String cardNumber,
    required String vehicleType,
    required String vehicleName,
    required String vehiclePlate,
  }) async {
    try {
      final dto = DriverSignUpDto(
        firstName: firstName, 
        lastName: lastName,
        email: email, 
        password: password, 
        phoneNumber: phoneNumber,
        dni: dni, 
        licenseNumber: licenseNumber, 
        culCertificate: culCertificate,
        cardNumber: cardNumber,
        vehicle: VehicleDto(
          type: vehicleType,
          name: vehicleName,
          licenseNumber: vehiclePlate,
        ),
      );
      
      final response = await apiService.registerDriver(dto);
      return Right(response.data['message'] ?? 'Registro exitoso.');
    } on DioException catch (e) {
      return Left(ServerFailure(_extractMessage(e)));
    } catch (e) {
      return const Left(ServerFailure('Error inesperado al registrar conductor.'));
    }
  }

  String _extractMessage(DioException e) {
    if (e.response?.data != null && e.response?.data is Map) {
      return e.response?.data['message'] ?? 'Error del servidor.';
    }
    return 'Error al conectar con el servidor.';
  }
}
