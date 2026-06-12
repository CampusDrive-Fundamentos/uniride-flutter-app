import 'user.dart';

class Driver extends User {
  final String dni;
  final String licenseNumber;
  final bool isBlocked;

  const Driver({
    required super.id,
    required super.username,
    required super.email,
    required this.dni,
    required this.licenseNumber,
    this.isBlocked = false,
  });

  @override
  List<Object?> get props => [id, username, email, dni, licenseNumber, isBlocked];
}