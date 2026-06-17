import 'package:equatable/equatable.dart';
import 'location.dart';

class RouteEntity extends Equatable {
  final int id;
  final int leaderId;
  final String startCampus;
  final LocationEntity startLocation;
  final LocationEntity destination;
  final String? encodedPolyline;
  final double totalDistanceKm;
  final String visibility;
  final List<LocationEntity> waypoints;

  const RouteEntity({
    required this.id,
    required this.leaderId,
    required this.startCampus,
    required this.startLocation,
    required this.destination,
    this.encodedPolyline,
    required this.totalDistanceKm,
    required this.visibility,
    required this.waypoints,
  });

  @override
  List<Object?> get props => [
        id,
        leaderId,
        startCampus,
        startLocation,
        destination,
        encodedPolyline,
        totalDistanceKm,
        visibility,
        waypoints,
      ];
}
