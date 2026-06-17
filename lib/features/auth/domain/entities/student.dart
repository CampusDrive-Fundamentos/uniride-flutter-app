import 'user.dart';

class Student extends User {
  final String universityName;
  final String tiuPhotoUrl;

  const Student({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.username,
    required super.email,
    required super.phoneNumber,
    required super.role,
    required this.universityName,
    required this.tiuPhotoUrl,
    super.cardNumber,
    super.vehicle,
  });

  bool get isInstitutionalEmail => email.endsWith('.edu.pe') || email.endsWith('.edu');

  @override
  List<Object?> get props => [id, firstName, lastName, username, email, phoneNumber, role, universityName, tiuPhotoUrl, cardNumber, vehicle];
}
