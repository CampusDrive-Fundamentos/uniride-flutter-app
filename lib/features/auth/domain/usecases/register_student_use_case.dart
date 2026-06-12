import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class RegisterStudentUseCase {
  final AuthRepository repository;

  RegisterStudentUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
    required String universityName,
    required File tiuPhoto,
  }) async {
    if (!email.contains('.edu')) {
      return Left(ValidationFailure('Correo institucional inválido.'));
    }
    
    return await repository.registerStudent(
      username: username,
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      universityName: universityName,
      tiuPhoto: tiuPhoto,
    );
  }
}