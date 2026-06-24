import 'package:equatable/equatable.dart';
import 'passenger_entity.dart';

class BookingEntity extends Equatable {
  final int id;
  final int leaderId;
  final int routeId;
  final String status;
  final String? securityPin;
  final List<PassengerEntity> passengers;
  final String? destinationAddress;
  final double? price;
  final String? departureTime;
  final double? startLat;
  final double? startLng;
  final double? destinationLat;
  final double? destinationLng;
  final String? encodedPolyline;

  const BookingEntity({
    required this.id,
    required this.leaderId,
    required this.routeId,
    required this.status,
    this.securityPin,
    required this.passengers,
    this.destinationAddress,
    this.price,
    this.departureTime,
    this.startLat,
    this.startLng,
    this.destinationLat,
    this.destinationLng,
    this.encodedPolyline,
  });

  BookingEntity copyWith({
    int? id,
    int? leaderId,
    int? routeId,
    String? status,
    String? securityPin,
    List<PassengerEntity>? passengers,
    String? destinationAddress,
    double? price,
    String? departureTime,
    double? startLat,
    double? startLng,
    double? destinationLat,
    double? destinationLng,
    String? encodedPolyline,
  }) {
    return BookingEntity(
      id: id ?? this.id,
      leaderId: leaderId ?? this.leaderId,
      routeId: routeId ?? this.routeId,
      status: status ?? this.status,
      securityPin: securityPin ?? this.securityPin,
      passengers: passengers ?? this.passengers,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      price: price ?? this.price,
      departureTime: departureTime ?? this.departureTime,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      encodedPolyline: encodedPolyline ?? this.encodedPolyline,
    );
  }

  @override
  List<Object?> get props => [
        id,
        leaderId,
        routeId,
        status,
        securityPin,
        passengers,
        destinationAddress,
        price,
        departureTime,
        startLat,
        startLng,
        destinationLat,
        destinationLng,
        encodedPolyline,
      ];
}
