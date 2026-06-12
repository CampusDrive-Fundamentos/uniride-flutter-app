import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class OnboardingRepository {
  Future<Either<Failure, void>> registerVehicle(String model, String color, String plate);
  Future<Either<Failure, void>> linkPaymentCard(String cardNumber, String expiryDate, String cvv);
}