class DriverSignUpDto {
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phoneNumber;
  final String dni;
  final String licenseNumber;
  final String culCertificate;

  DriverSignUpDto({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.dni,
    required this.licenseNumber,
    required this.culCertificate,
  });

  Map<String, dynamic> toJson() => {
    "username": username,
    "firstName": firstName,
    "lastName": lastName,
    "email": email,
    "password": password,
    "phoneNumber": phoneNumber,
    "dni": dni,
    "licenseNumber": licenseNumber,
    "culCertificate": culCertificate,
  };
}