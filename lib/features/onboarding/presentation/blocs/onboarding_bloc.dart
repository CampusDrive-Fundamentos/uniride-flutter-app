import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/register_vehicle_use_case.dart';
import '../../domain/usecases/link_payment_card_use_case.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final RegisterVehicleUseCase registerVehicleUseCase;
  final LinkPaymentCardUseCase linkPaymentCardUseCase;

  OnboardingBloc({
    required this.registerVehicleUseCase,
    required this.linkPaymentCardUseCase,
  }) : super(OnboardingInitial()) {
    
    on<SubmitVehicleEvent>((event, emit) async {
      emit(OnboardingLoading());
      final result = await registerVehicleUseCase(event.model, event.color, event.plate);
      result.fold(
        (failure) => emit(OnboardingFailure(message: failure.message)), // <-- Aquí
        (_) => emit(VehicleRegisteredSuccess()),             
      );
    });

    on<SubmitCardEvent>((event, emit) async {
      emit(OnboardingLoading());
      final result = await linkPaymentCardUseCase(event.cardNumber, event.expiry, event.cvv);
      result.fold(
        (failure) => emit(OnboardingFailure(message: failure.message)), 
        (_) => emit(CardLinkedSuccess()),                    
      );
    });
  }
}