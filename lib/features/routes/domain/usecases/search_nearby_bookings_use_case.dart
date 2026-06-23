import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking_entity.dart';
import '../repositories/routes_repository.dart';

class SearchNearbyBookingsParams {
  final String campus;
  final double lat;
  final double lng;

  SearchNearbyBookingsParams({
    required this.campus,
    required this.lat,
    required this.lng,
  });
}

class SearchNearbyBookingsUseCase {
  final RoutesRepository repository;

  SearchNearbyBookingsUseCase(this.repository);

  Future<Either<Failure, List<BookingEntity>>> call(SearchNearbyBookingsParams params) async {
    final bookingsResult = await repository.searchNearbyBookings(
      campus: params.campus,
      lat: params.lat,
      lng: params.lng,
    );

    return await bookingsResult.fold(
      (failure) async => Left(failure),
      (bookings) async {
        final List<Future<BookingEntity>> enrichmentFutures = bookings.map((booking) async {
          final routeResult = await repository.getRouteById(booking.routeId);
          
          return routeResult.fold(
            (failure) => booking, // If route fails, keep booking as is
            (route) {
              // Enriquecer con datos de la ruta
              return booking.copyWith(
                destinationAddress: route.destination.address,
                price: 10.0 + (route.totalDistanceKm * 1.5), // Lógica de precio consistente
                departureTime: '13:00', // Mock de hora ya que no está en RouteEntity aún
                startLat: route.startLocation.latitude,
                startLng: route.startLocation.longitude,
                destinationLat: route.destination.latitude,
                destinationLng: route.destination.longitude,
                encodedPolyline: route.encodedPolyline,
              );
            },
          );
        }).toList();

        final enrichedBookings = await Future.wait(enrichmentFutures);
        return Right(enrichedBookings);
      },
    );
  }
}
