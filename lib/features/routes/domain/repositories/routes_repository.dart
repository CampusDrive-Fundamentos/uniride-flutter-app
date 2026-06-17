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
  });

  Future<Either<Failure, BookingEntity>> createBooking({
    required int routeId,
  });

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

  Future<Either<Failure, List<RouteEntity>>> getRoutesByCampus({
    required String campus,
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
