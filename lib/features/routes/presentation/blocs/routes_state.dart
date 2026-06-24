import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_entity.dart';

abstract class RoutesState extends Equatable {
  const RoutesState();

  @override
  List<Object?> get props => [];
}

class RoutesInitial extends RoutesState {}

class RoutesLoading extends RoutesState {}

class NearbyBookingsLoaded extends RoutesState {
  final List<BookingEntity> bookings;

  const NearbyBookingsLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

class RouteAndBookingCreated extends RoutesState {
  final BookingEntity booking;

  const RouteAndBookingCreated(this.booking);

  @override
  List<Object?> get props => [booking];
}

class JoinedBookingSuccess extends RoutesState {
  final BookingEntity booking;

  const JoinedBookingSuccess(this.booking);

  @override
  List<Object?> get props => [booking];
}

class RoutesError extends RoutesState {
  final String message;

  const RoutesError(this.message);

  @override
  List<Object?> get props => [message];
}

class CurrentBookingLoaded extends RoutesState {
  final BookingEntity booking;

  const CurrentBookingLoaded(this.booking);

  @override
  List<Object?> get props => [booking];
}

class CurrentBookingEmpty extends RoutesState {}

class LockAndPublishSuccess extends RoutesState {
  final BookingEntity booking;

  const LockAndPublishSuccess(this.booking);

  @override
  List<Object?> get props => [booking];
}

class LeaveBookingSuccess extends RoutesState {}

class CancelBookingSuccess extends RoutesState {}

class ConfirmArrivalSuccess extends RoutesState {}

class UpdatePaymentSuccess extends RoutesState {
  final BookingEntity booking;

  const UpdatePaymentSuccess(this.booking);

  @override
  List<Object?> get props => [booking];
}
