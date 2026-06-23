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
            // Retornamos directamente la reserva (Booking).
            // El viaje se creará recién cuando el Líder decida publicar/buscar conductor (Lock).
            return Right(booking);
          },
        );
      },
    );
  }
}
