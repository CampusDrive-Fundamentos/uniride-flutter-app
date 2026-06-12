abstract class OnboardingEvent {}

class SubmitVehicleEvent extends OnboardingEvent {
  final String model;
  final String color;
  final String plate;
  SubmitVehicleEvent({required this.model, required this.color, required this.plate});
}

class SubmitCardEvent extends OnboardingEvent {
  final String cardNumber;
  final String expiry;
  final String cvv;
  SubmitCardEvent({required this.cardNumber, required this.expiry, required this.cvv});
}