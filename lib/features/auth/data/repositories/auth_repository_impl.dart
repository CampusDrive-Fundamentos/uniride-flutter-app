import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/auth_api_service.dart';
import '../models/student_signup_dto.dart';
import '../models/driver_signup_dto.dart';

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
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        return const Left(ServerFailure('Credenciales incorrectas.'));
      }
      return Left(ServerFailure(e.response?.data['message'] ?? 'Error al conectar con el servidor.'));
    } catch (e) {
      return Left(ServerFailure('Ocurrió un error inesperado.'));
    }
  }

  @override
  Future<Either<Failure, String>> registerStudent({
    required String username, required String firstName, required String lastName,
    required String email, required String password, required String phoneNumber,
    required String universityName, required File tiuPhoto,
  }) async {
    try {
      final dto = StudentSignUpDto(
        username: username, firstName: firstName, lastName: lastName,
        email: email, password: password, phoneNumber: phoneNumber,
        universityName: universityName, tiuPhoto: tiuPhoto,
      );
      
      final response = await apiService.registerStudent(dto);
      
      final token = response.data['token'];
      await secureStorage.write(key: 'jwt_token', value: token);
      return Right(token);
    } on DioException catch (e) {
      print("====================================");
      print("Error de Red (DioException):");
      print("Tipo de DioException: ${e.type}"); 
      print("Error Interno: ${e.error}");       
      print("Código de estado HTTP: ${e.response?.statusCode}");
      print("Cuerpo de respuesta (Data): ${e.response?.data}");
      print("====================================");

      if (e.response?.statusCode == 409) return const Left(ServerFailure('El usuario o correo ya existe.'));
      
      String errorMessage = 'Error en el registro del estudiante.';
      if (e.response?.data != null && e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      
      return Left(ServerFailure(errorMessage));
    } catch (e) {
      print("====================================");
      print("Error Inesperado en Flutter:");
      print(e.toString());
      print("====================================");
      return const Left(ServerFailure('Ocurrió un error inesperado al procesar los datos.'));
    }
  }

  @override
  Future<Either<Failure, String>> registerDriver({
    required String username, required String firstName, required String lastName,
    required String email, required String password, required String phoneNumber,
    required String dni, required String licenseNumber, required String culCertificate,
  }) async {
    try {
      final dto = DriverSignUpDto(
        username: username, firstName: firstName, lastName: lastName,
        email: email, password: password, phoneNumber: phoneNumber,
        dni: dni, licenseNumber: licenseNumber, culCertificate: culCertificate,
      );
      
      final response = await apiService.registerDriver(dto);
      final token = response.data['token'];
      await secureStorage.write(key: 'jwt_token', value: token);
      return Right(token);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) return const Left(ServerFailure('El conductor o correo ya existe.'));
      return Left(ServerFailure(e.response?.data['message'] ?? 'Error en el registro del conductor.'));
    }
  }
}