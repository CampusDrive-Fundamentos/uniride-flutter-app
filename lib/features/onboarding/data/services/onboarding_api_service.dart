import 'package:dio/dio.dart';

class OnboardingApiService {
  final Dio _dio;

  OnboardingApiService(this._dio);

  Future<Response> registerVehicle(String model, String color, String plate) async {
    return await _dio.post(
      '/api/v1/drivers/vehicle', 
      data: {
        "model": model,
        "color": color,
        "plate": plate,
      },
    );
  }

  Future<Response> linkPaymentCard(String cardNumber, String expiryDate, String cvv) async {
    return await _dio.post(
      '/api/v1/finance/drivers/link-card', 
      data: {
        "cardNumber": cardNumber,
        "expiryDate": expiryDate,
        "cvv": cvv,
      },
    );
  }
}