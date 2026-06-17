import 'package:equatable/equatable.dart';

class LocationEntity extends Equatable {
  final double latitude;
  final double longitude;
  final String address;
  final int? passengerId;
  final double? distanceFromStartKm;

  const LocationEntity({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.passengerId,
    this.distanceFromStartKm,
  });

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        address,
        passengerId,
        distanceFromStartKm,
      ];
}
