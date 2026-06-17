import 'user.dart';

class Driver extends User {
  final String dni;
  final String licenseNumber;
  final bool isBlocked;

  const Driver({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.username,
    required super.email,
    required super.phoneNumber,
    required super.role,
    required this.dni,
    required this.licenseNumber,
    this.isBlocked = false,
    super.cardNumber,
    super.vehicle,
  });

  @override
  List<Object?> get props => [id, firstName, lastName, username, email, phoneNumber, role, dni, licenseNumber, isBlocked, cardNumber, vehicle];
}
