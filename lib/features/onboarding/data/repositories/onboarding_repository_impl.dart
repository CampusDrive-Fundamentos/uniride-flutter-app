import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../services/onboarding_api_service.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingApiService apiService;

  OnboardingRepositoryImpl(this.apiService);

  @override
  Future<Either<Failure, void>> registerVehicle(String model, String color, String plate) async {
    try {
      await apiService.registerVehicle(model, color, plate);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data['message'] ?? 'Error al registrar vehículo'));
    }
  }

  @override
  Future<Either<Failure, void>> linkPaymentCard(String cardNumber, String expiryDate, String cvv) async {
    try {
      await apiService.linkPaymentCard(cardNumber, expiryDate, cvv);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data['message'] ?? 'Error al vincular tarjeta'));
    }
  }
}