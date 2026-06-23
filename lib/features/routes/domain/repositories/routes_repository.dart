import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/route_entity.dart';
import '../entities/booking_entity.dart';

abstract class RoutesRepository {
  Future<Either<Failure, RouteEntity>> createRoute({
    required String campus,
    required String destinationAddress,
    required double destinationLat,
    required double destinationLng,
    required double startLat,
    required double startLng,
  });

  Future<Either<Failure, BookingEntity>> createBooking({
    required int routeId,
  });

  Future<Either<Failure, RouteEntity>> getRouteById(int routeId);

  Future<Either<Failure, List<BookingEntity>>> searchNearbyBookings({
    required String campus,
    required double lat,
    required double lng,
  });

  Future<Either<Failure, BookingEntity>> joinBooking({
    required int bookingId,
    required double lat,
    required double lng,
    required String address,
  });

  Future<Either<Failure, BookingEntity>> getCurrentBooking();

  Future<Either<Failure, BookingEntity>> lockBooking({required int bookingId});

  Future<Either<Failure, BookingEntity>> leaveBooking({
    required int bookingId,
    required double lat,
    required double lng,
  });

  Future<Either<Failure, void>> cancelBooking({required int bookingId});

  Future<Either<Failure, void>> confirmArrival({
    required int tripId,
    required int passengerId,
  });

  Future<Either<Failure, BookingEntity>> updatePayment({
    required int bookingId,
    required int passengerId,
    required String method,
  });

  Future<Either<Failure, void>> createTrip({
    required int bookingId,
    required int routeId,
    required String campus,
    required String securityCode,
    required double totalAmount,
    required List<int> passengerIds,
  });
}
