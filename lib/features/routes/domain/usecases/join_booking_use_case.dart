import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking_entity.dart';
import '../repositories/routes_repository.dart';

class JoinBookingParams {
  final int bookingId;
  final double lat;
  final double lng;
  final String address;

  JoinBookingParams({
    required this.bookingId,
    required this.lat,
    required this.lng,
    required this.address,
  });
}

class JoinBookingUseCase {
  final RoutesRepository repository;

  JoinBookingUseCase(this.repository);

  Future<Either<Failure, BookingEntity>> call(JoinBookingParams params) async {
    return await repository.joinBooking(
      bookingId: params.bookingId,
      lat: params.lat,
      lng: params.lng,
      address: params.address,
    );
  }
}
