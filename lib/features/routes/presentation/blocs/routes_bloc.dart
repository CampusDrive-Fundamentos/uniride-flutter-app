import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_route_and_booking_use_case.dart';
import '../../domain/usecases/search_nearby_bookings_use_case.dart';
import '../../domain/usecases/join_booking_use_case.dart';
import '../../domain/repositories/routes_repository.dart';
import 'routes_event.dart';
import 'routes_state.dart';

class RoutesBloc extends Bloc<RoutesEvent, RoutesState> {
  final CreateRouteAndBookingUseCase createRouteAndBookingUseCase;
  final SearchNearbyBookingsUseCase searchNearbyBookingsUseCase;
  final JoinBookingUseCase joinBookingUseCase;
  final RoutesRepository repository;

  RoutesBloc({
    required this.createRouteAndBookingUseCase,
    required this.searchNearbyBookingsUseCase,
    required this.joinBookingUseCase,
    required this.repository,
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
          startLat: event.startLat,
          startLng: event.startLng,
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

    on<LoadCurrentBookingEvent>((event, emit) async {
      emit(RoutesLoading());
      final result = await repository.getCurrentBooking();
      result.fold(
        (failure) => emit(CurrentBookingEmpty()),
        (booking) => emit(CurrentBookingLoaded(booking)),
      );
    });

    on<LockAndPublishBookingEvent>((event, emit) async {
      emit(RoutesLoading());
      final lockResult = await repository.lockBooking(bookingId: event.bookingId);
      await lockResult.fold(
        (failure) async => emit(RoutesError(failure.message)),
        (lockedBooking) async {
          // MANTENEMOS EL PIN ORIGINAL: El usuario desea que el PIN sea el mismo que se generó al inicio.
          // Ignoramos el PIN que devuelve el servidor tras bloquear para evitar confusiones al taxista.
          final pinSincronizado = event.securityCode;
          
          double amount = 10.0 + (event.totalDistanceKm * 1.5);
          final tripResult = await repository.createTrip(
            bookingId: event.bookingId,
            routeId: event.routeId,
            campus: event.campus,
            securityCode: pinSincronizado,
            totalAmount: amount,
            passengerIds: event.passengerIds,
          );
          tripResult.fold(
            (failure) => emit(RoutesError(failure.message)),
            (_) => emit(LockAndPublishSuccess(lockedBooking.copyWith(securityPin: pinSincronizado))),
          );
        },
      );
    });

    on<LeaveBookingEvent>((event, emit) async {
      emit(RoutesLoading());
      final result = await repository.leaveBooking(
        bookingId: event.bookingId,
        lat: event.lat,
        lng: event.lng,
      );
      result.fold(
        (failure) => emit(RoutesError(failure.message)),
        (_) {
          emit(LeaveBookingSuccess());
          emit(CurrentBookingEmpty());
        },
      );
    });

    on<CancelBookingEvent>((event, emit) async {
      emit(RoutesLoading());

      // NUEVO: Si hay un viaje asociado (anuncio ya publicado a taxistas), lo cancelamos primero
      if (event.tripId != null) {
        await repository.cancelTrip(
          tripId: event.tripId!,
          reason: 'Líder canceló el grupo desde la app',
        );
      }

      // Luego borramos el Booking (lo cual borra también la Ruta en el backend)
      final result = await repository.cancelBooking(bookingId: event.bookingId);
      result.fold(
        (failure) => emit(RoutesError(failure.message)),
        (_) {
          emit(CancelBookingSuccess());
          emit(CurrentBookingEmpty());
        },
      );
    });

    on<ConfirmArrivalEvent>((event, emit) async {
      emit(RoutesLoading());
      final result = await repository.confirmArrival(
        tripId: event.tripId,
        passengerId: event.passengerId,
      );
      result.fold(
        (failure) => emit(RoutesError(failure.message)),
        (_) => emit(ConfirmArrivalSuccess()),
      );
    });

    on<UpdatePassengerPaymentEvent>((event, emit) async {
      emit(RoutesLoading());
      final result = await repository.updatePayment(
        bookingId: event.bookingId,
        passengerId: event.passengerId,
        method: event.method,
      );
      result.fold(
        (failure) => emit(RoutesError(failure.message)),
        (booking) => emit(UpdatePaymentSuccess(booking)),
      );
    });
  }
}