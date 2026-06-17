class StudentSignUpDto {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phoneNumber;
  final String universityName;
  final String tiuPhoto; // Base64 or URL string as per backend contract

  StudentSignUpDto({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.universityName,
    required this.tiuPhoto,
  });

  Map<String, dynamic> toJson() => {
    "firstName": firstName,
    "lastName": lastName,
    "email": email,
    "password": password,
    "phoneNumber": phoneNumber,
    "universityName": universityName,
    "tiuPhoto": tiuPhoto,
  };
}
