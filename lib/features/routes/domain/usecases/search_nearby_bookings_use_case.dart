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
    return await repository.searchNearbyBookings(
      campus: params.campus,
      lat: params.lat,
      lng: params.lng,
    );
  }
}
