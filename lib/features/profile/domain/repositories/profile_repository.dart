import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';

abstract class ProfileRepository {
  Future<Either<Failure, User>> getCurrentUser();
  
  Future<Either<Failure, User>> updateStudentProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  });

  Future<Either<Failure, User>> updateDriverProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String cardNumber,
    required String vehicleType,
    required String vehicleName,
    required String vehiclePlate,
  });
}
