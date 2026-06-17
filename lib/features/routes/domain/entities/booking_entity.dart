import 'package:equatable/equatable.dart';
import 'passenger_entity.dart';

class BookingEntity extends Equatable {
  final int id;
  final int leaderId;
  final int routeId;
  final String status;
  final String? securityPin;
  final List<PassengerEntity> passengers;

  const BookingEntity({
    required this.id,
    required this.leaderId,
    required this.routeId,
    required this.status,
    this.securityPin,
    required this.passengers,
  });

  @override
  List<Object?> get props => [id, leaderId, routeId, status, securityPin, passengers];
}
