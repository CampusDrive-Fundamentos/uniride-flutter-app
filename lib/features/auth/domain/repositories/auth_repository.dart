import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, String>> login(String email, String password);
  
  Future<Either<Failure, String>> registerStudent({
    required String username, required String firstName, required String lastName,
    required String email, required String password, required String phoneNumber,
    required String universityName, required File tiuPhoto,
  });

  Future<Either<Failure, String>> registerDriver({
    required String username, required String firstName, required String lastName,
    required String email, required String password, required String phoneNumber,
    required String dni, required String licenseNumber, required String culCertificate,
    required String cardNumber,
    required String vehicleType,
    required String vehicleName,
    required String vehiclePlate,
  });
}
