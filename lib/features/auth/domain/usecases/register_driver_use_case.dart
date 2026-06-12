import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class RegisterDriverParams {
  final String username, firstName, lastName, email, password, phone, dni, license, cul;
  RegisterDriverParams({
    required this.username, required this.firstName, required this.lastName,
    required this.email, required this.password, required this.phone,
    required this.dni, required this.license, required this.cul
  });
}

class RegisterDriverUseCase implements UseCase<String, RegisterDriverParams> {
  final AuthRepository repository;
  RegisterDriverUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(RegisterDriverParams params) async {
    if (params.dni.length != 8) return const Left(ValidationFailure('El DNI debe tener 8 dígitos'));
    return await repository.registerDriver(
      username: params.username, firstName: params.firstName, lastName: params.lastName,
      email: params.email, password: params.password, phoneNumber: params.phone,
      dni: params.dni, licenseNumber: params.license, culCertificate: params.cul,
    );
  }
}