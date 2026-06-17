import 'package:equatable/equatable.dart';

class PassengerEntity extends Equatable {
  final int studentId;
  final String role;
  final String paymentStatus;
  final String? paymentMethod;

  const PassengerEntity({
    required this.studentId,
    required this.role,
    required this.paymentStatus,
    this.paymentMethod,
  });

  @override
  List<Object?> get props => [studentId, role, paymentStatus, paymentMethod];
}
