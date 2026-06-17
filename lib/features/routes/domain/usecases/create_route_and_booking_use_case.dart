import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking_entity.dart';
import '../repositories/routes_repository.dart';

class CreateRouteAndBookingParams {
  final String campus;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;

  CreateRouteAndBookingParams({
    required this.campus,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
  });
}

class CreateRouteAndBookingUseCase {
  final RoutesRepository repository;

  CreateRouteAndBookingUseCase(this.repository);

  Future<Either<Failure, BookingEntity>> call(CreateRouteAndBookingParams params) async {
    // 1. Crear la ruta
    final routeResult = await repository.createRoute(
      campus: params.campus,
      destinationAddress: params.destinationAddress,
      destinationLat: params.destinationLat,
      destinationLng: params.destinationLng,
    );

    return await routeResult.fold(
      (failure) async => Left(failure),
      (route) async {
        // 2. Crear la reserva (grupo) vinculada a esa ruta
        final bookingResult = await repository.createBooking(routeId: route.id);
        
        return await bookingResult.fold(
          (failure) async => Left(failure),
          (booking) async {
            // 3. Crear automáticamente el viaje en estado REQUESTED para la bolsa de viajes
            final tripResult = await repository.createTrip(
              bookingId: booking.id,
              routeId: route.id,
              campus: params.campus,
              securityCode: booking.securityPin ?? '0000',
              totalAmount: 10.0 + (route.totalDistanceKm * 1.5),
              passengerIds: [booking.leaderId],
            );
            
            return tripResult.fold(
              (failure) => Left(failure),
              (_) => Right(booking),
            );
          },
        );
      },
    );
  }
}
