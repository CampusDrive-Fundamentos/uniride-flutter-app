import '../../../auth/data/models/vehicle_dto.dart';

class UpdateDriverProfileRequestDto {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String cardNumber;
  final VehicleDto vehicle;

  UpdateDriverProfileRequestDto({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.cardNumber,
    required this.vehicle,
  });

  Map<String, dynamic> toJson() => {
    "firstName": firstName,
    "lastName": lastName,
    "phoneNumber": phoneNumber,
    "cardNumber": cardNumber,
    "vehicle": vehicle.toJson(),
  };
}
