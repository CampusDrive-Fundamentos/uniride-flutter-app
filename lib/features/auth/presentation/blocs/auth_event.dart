import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const LoginSubmitted({required this.email, required this.password});
}

// FALTABA ESTE EVENTO
class RegisterStudentEvent extends AuthEvent {
  final String username, firstName, lastName, email, password, phoneNumber, universityName;
  final File tiuPhoto;

  const RegisterStudentEvent({
    required this.username, required this.firstName, required this.lastName,
    required this.email, required this.password, required this.phoneNumber,
    required this.universityName, required this.tiuPhoto,
  });
}

class RegisterDriverEvent extends AuthEvent {
  final String username, firstName, lastName, email, password, phoneNumber, dni, licenseNumber, culCertificate;

  const RegisterDriverEvent({
    required this.username, required this.firstName, required this.lastName,
    required this.email, required this.password, required this.phoneNumber,
    required this.dni, required this.licenseNumber, required this.culCertificate,
  });
}