class UpdateStudentProfileRequestDto {
  final String firstName;
  final String lastName;
  final String phoneNumber;

  UpdateStudentProfileRequestDto({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
    "firstName": firstName,
    "lastName": lastName,
    "phoneNumber": phoneNumber,
  };
}
