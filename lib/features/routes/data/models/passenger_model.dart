import '../../domain/entities/passenger_entity.dart';

class PassengerModel extends PassengerEntity {
  const PassengerModel({
    required super.studentId,
    required super.role,
    required super.paymentStatus,
    super.paymentMethod,
  });

  factory PassengerModel.fromJson(Map<String, dynamic> json) {
    return PassengerModel(
      studentId: (json['studentId'] as num).toInt(),
      role: json['role'] as String? ?? 'PASSENGER',
      paymentStatus: json['paymentStatus'] as String? ?? 'PENDING',
      paymentMethod: json['paymentMethod'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'role': role,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
    };
  }
}
