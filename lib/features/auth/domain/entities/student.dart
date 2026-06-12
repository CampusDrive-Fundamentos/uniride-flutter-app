import 'user.dart';

class Student extends User {
  final String universityName;
  final String tiuPhotoUrl;

  const Student({
    required super.id,
    required super.username,
    required super.email,
    required this.universityName,
    required this.tiuPhotoUrl,
  });

  // Validaciones de negocio puras
  bool get isInstitutionalEmail => email.endsWith('.edu.pe') || email.endsWith('.edu');

  @override
  List<Object?> get props => [id, username, email, universityName, tiuPhotoUrl];
}