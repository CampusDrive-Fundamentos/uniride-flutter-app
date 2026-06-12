abstract class OnboardingState {}

class OnboardingInitial extends OnboardingState {}
class OnboardingLoading extends OnboardingState {}
class VehicleRegisteredSuccess extends OnboardingState {}
class CardLinkedSuccess extends OnboardingState {}
class OnboardingFailure extends OnboardingState {
  final String message;
  OnboardingFailure({required this.message});
}