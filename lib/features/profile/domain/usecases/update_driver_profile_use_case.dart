import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user.dart';
import '../repositories/profile_repository.dart';

class UpdateDriverParams {
  final String firstName, lastName, phoneNumber, cardNumber, vehicleType, vehicleName, vehiclePlate;
  UpdateDriverParams({
    required this.firstName, required this.lastName, required this.phoneNumber,
    required this.cardNumber, required this.vehicleType, required this.vehicleName, required this.vehiclePlate,
  });
}

class UpdateDriverProfileUseCase implements UseCase<User, UpdateDriverParams> {
  final ProfileRepository repository;
  UpdateDriverProfileUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(UpdateDriverParams params) async {
    return await repository.updateDriverProfile(
      firstName: params.firstName,
      lastName: params.lastName,
      phoneNumber: params.phoneNumber,
      cardNumber: params.cardNumber,
      vehicleType: params.vehicleType,
      vehicleName: params.vehicleName,
      vehiclePlate: params.vehiclePlate,
    );
  }
}
