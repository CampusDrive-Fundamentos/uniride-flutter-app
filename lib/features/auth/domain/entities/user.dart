import 'package:equatable/equatable.dart';

class VehicleEntity extends Equatable {
  final String type;
  final String name;
  final String licenseNumber;

  const VehicleEntity({
    required this.type,
    required this.name,
    required this.licenseNumber,
  });

  @override
  List<Object?> get props => [type, name, licenseNumber];
}

abstract class User extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String phoneNumber;
  final String role; // Agregado para identificar el rol fácilmente
  final String? cardNumber;
  final VehicleEntity? vehicle;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.cardNumber,
    this.vehicle,
  });

  @override
  List<Object?> get props => [id, firstName, lastName, username, email, phoneNumber, role, cardNumber, vehicle];
}
