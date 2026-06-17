import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user.dart';
import '../repositories/profile_repository.dart';

class UpdateStudentParams {
  final String firstName, lastName, phoneNumber;
  UpdateStudentParams({required this.firstName, required this.lastName, required this.phoneNumber});
}

class UpdateStudentProfileUseCase implements UseCase<User, UpdateStudentParams> {
  final ProfileRepository repository;
  UpdateStudentProfileUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(UpdateStudentParams params) async {
    return await repository.updateStudentProfile(
      firstName: params.firstName,
      lastName: params.lastName,
      phoneNumber: params.phoneNumber,
    );
  }
}
