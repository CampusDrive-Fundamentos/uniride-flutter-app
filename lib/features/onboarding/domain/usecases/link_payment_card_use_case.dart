import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/onboarding_repository.dart';

class LinkPaymentCardUseCase {
  final OnboardingRepository repository;
  LinkPaymentCardUseCase(this.repository);

  Future<Either<Failure, void>> call(String cardNumber, String expiryDate, String cvv) async {
    if (cardNumber.length < 16) return const Left(ValidationFailure('Tarjeta inválida'));
    return await repository.linkPaymentCard(cardNumber, expiryDate, cvv);
  }
}