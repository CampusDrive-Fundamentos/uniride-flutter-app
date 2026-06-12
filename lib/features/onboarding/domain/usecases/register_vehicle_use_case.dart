import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/onboarding_repository.dart';

class RegisterVehicleUseCase {
  final OnboardingRepository repository;
  RegisterVehicleUseCase(this.repository);

  Future<Either<Failure, void>> call(String model, String color, String plate) async {
    final plateRegex = RegExp(r'^[A-Z0-9]{3}-[A-Z0-9]{3}$');
    if (!plateRegex.hasMatch(plate)) {
      return Left(ValidationFailure('Formato de placa inválido.'));
    }
    return await repository.registerVehicle(model, color, plate);
  }
}