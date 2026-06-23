import '../../domain/entities/booking_entity.dart';
import 'passenger_model.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.leaderId,
    required super.routeId,
    required super.status,
    super.securityPin,
    required List<PassengerModel> super.passengers,
    super.destinationAddress,
    super.price,
    super.departureTime,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: (json['id'] as num).toInt(),
      leaderId: (json['leaderId'] as num).toInt(),
      routeId: (json['routeId'] as num).toInt(),
      status: json['status'] as String? ?? 'OPEN',
      securityPin: json['securityPin'] as String?,
      passengers: json['passengers'] != null
          ? (json['passengers'] as List)
              .map((p) => PassengerModel.fromJson(Map<String, dynamic>.from(p as Map)))
              .toList()
          : [],
      destinationAddress: json['destinationAddress'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      departureTime: json['departureTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leaderId': leaderId,
      'routeId': routeId,
      'status': status,
      'securityPin': securityPin,
      'passengers': passengers.map((p) => (p as PassengerModel).toJson()).toList(),
      'destinationAddress': destinationAddress,
      'price': price,
      'departureTime': departureTime,
    };
  }
}
