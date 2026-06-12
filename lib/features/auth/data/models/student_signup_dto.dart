import 'dart:io';

class StudentSignUpDto {
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phoneNumber;
  final String universityName;
  final File tiuPhoto;

  StudentSignUpDto({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.universityName,
    required this.tiuPhoto,
  });
}