import 'package:equatable/equatable.dart';

abstract class RoutesEvent extends Equatable {
  const RoutesEvent();

  @override
  List<Object?> get props => [];
}

class SearchNearbyBookingsEvent extends RoutesEvent {
  final String campus;
  final double lat;
  final double lng;

  const SearchNearbyBookingsEvent({
    required this.campus,
    required this.lat,
    required this.lng,
  });

  @override
  List<Object?> get props => [campus, lat, lng];
}

class CreateRouteAndBookingEvent extends RoutesEvent {
  final String campus;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final String exitGate; // Adicional según US07 (Puerta de salida)
  final String departureTime; // Adicional según US07 (Hora de salida)

  const CreateRouteAndBookingEvent({
    required this.campus,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.exitGate,
    required this.departureTime,
  });

  @override
  List<Object?> get props => [
        campus,
        destinationAddress,
        destinationLat,
        destinationLng,
        exitGate,
        departureTime,
      ];
}

class JoinBookingEvent extends RoutesEvent {
  final int bookingId;
  final double lat;
  final double lng;
  final String address;

  const JoinBookingEvent({
    required this.bookingId,
    required this.lat,
    required this.lng,
    required this.address,
  });

  @override
  List<Object?> get props => [bookingId, lat, lng, address];
}

class LoadCurrentBookingEvent extends RoutesEvent {
  const LoadCurrentBookingEvent();
}

class LockAndPublishBookingEvent extends RoutesEvent {
  final int bookingId;
  final int routeId;
  final String campus;
  final String securityCode;
  final double totalDistanceKm;
  final List<int> passengerIds;

  const LockAndPublishBookingEvent({
    required this.bookingId,
    required this.routeId,
    required this.campus,
    required this.securityCode,
    required this.totalDistanceKm,
    required this.passengerIds,
  });

  @override
  List<Object?> get props => [bookingId, routeId, campus, securityCode, totalDistanceKm, passengerIds];
}

class LeaveBookingEvent extends RoutesEvent {
  final int bookingId;
  final double lat;
  final double lng;

  const LeaveBookingEvent({
    required this.bookingId,
    required this.lat,
    required this.lng,
  });

  @override
  List<Object?> get props => [bookingId, lat, lng];
}

class CancelBookingEvent extends RoutesEvent {
  final int bookingId;

  const CancelBookingEvent(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class ConfirmArrivalEvent extends RoutesEvent {
  final int tripId;
  final int passengerId;

  const ConfirmArrivalEvent({
    required this.tripId,
    required this.passengerId,
  });

  @override
  List<Object?> get props => [tripId, passengerId];
}

class UpdatePassengerPaymentEvent extends RoutesEvent {
  final int bookingId;
  final int passengerId;
  final String method;

  const UpdatePassengerPaymentEvent({
    required this.bookingId,
    required this.passengerId,
    required this.method,
  });

  @override
  List<Object?> get props => [bookingId, passengerId, method];
}
