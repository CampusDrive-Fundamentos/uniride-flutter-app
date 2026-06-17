import '../../../auth/data/models/vehicle_dto.dart';

class UserProfileResponseDto {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String role;
  final String? cardNumber;
  final VehicleDto? vehicle;

  UserProfileResponseDto({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.cardNumber,
    this.vehicle,
  });

  factory UserProfileResponseDto.fromJson(Map<String, dynamic> json) {
    return UserProfileResponseDto(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? '',
      cardNumber: json['cardNumber'],
      vehicle: json['vehicle'] != null ? VehicleDto.fromJson(json['vehicle']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "firstName": firstName,
    "lastName": lastName,
    "email": email,
    "phoneNumber": phoneNumber,
    "role": role,
    "cardNumber": cardNumber,
    "vehicle": vehicle?.toJson(),
  };
}
