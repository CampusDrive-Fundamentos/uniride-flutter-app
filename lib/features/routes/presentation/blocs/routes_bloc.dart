import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_route_and_booking_use_case.dart';
import '../../domain/usecases/search_nearby_bookings_use_case.dart';
import '../../domain/usecases/join_booking_use_case.dart';
import 'routes_event.dart';
import 'routes_state.dart';

class RoutesBloc extends Bloc<RoutesEvent, RoutesState> {
  final CreateRouteAndBookingUseCase createRouteAndBookingUseCase;
  final SearchNearbyBookingsUseCase searchNearbyBookingsUseCase;
  final JoinBookingUseCase joinBookingUseCase;

  RoutesBloc({
    required this.createRouteAndBookingUseCase,
    required this.searchNearbyBookingsUseCase,
    required this.joinBookingUseCase,
  }) : super(RoutesInitial()) {

    on<SearchNearbyBookingsEvent>((event, emit) async {
      emit(RoutesLoading());
      final result = await searchNearbyBookingsUseCase(
        SearchNearbyBookingsParams(
          campus: event.campus,
          lat: event.lat,
          lng: event.lng,
        ),
      );
      result.fold(
        (failure) => emit(RoutesError(failure.message)),
        (bookings) => emit(NearbyBookingsLoaded(bookings)),
      );
    });

    on<CreateRouteAndBookingEvent>((event, emit) async {
      emit(RoutesLoading());
      final result = await createRouteAndBookingUseCase(
        CreateRouteAndBookingParams(
          campus: event.campus,
          destinationAddress: event.destinationAddress,
          destinationLat: event.destinationLat,
          destinationLng: event.destinationLng,
        ),
      );
      result.fold(
        (failure) => emit(RoutesError(failure.message)),
        (booking) => emit(RouteAndBookingCreated(booking)),
      );
    });

    on<JoinBookingEvent>((event, emit) async {
      emit(RoutesLoading());
      final result = await joinBookingUseCase(
        JoinBookingParams(
          bookingId: event.bookingId,
          lat: event.lat,
          lng: event.lng,
          address: event.address,
        ),
      );
      result.fold(
        (failure) => emit(RoutesError(failure.message)),
        (booking) => emit(JoinedBookingSuccess(booking)),
      );
    });
  }
}
