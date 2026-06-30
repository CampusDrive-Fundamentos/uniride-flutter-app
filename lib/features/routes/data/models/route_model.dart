import '../../domain/entities/route_entity.dart';
import 'location_model.dart';

class RouteModel extends RouteEntity {
  const RouteModel({
    required super.id,
    required super.leaderId,
    required super.startCampus,
    required LocationModel super.startLocation,
    required LocationModel super.destination,
    super.encodedPolyline,
    required super.totalDistanceKm,
    required super.visibility,
    required List<LocationModel> super.waypoints,
  });

  static String _mapBackendCampusToApp(String backendCampus) {
    switch (backendCampus) {
      case 'UPC_MONTERRICO':
        return 'MONTERRICO';
      case 'UPC_SAN_ISIDRO':
        return 'SAN ISIDRO';
      case 'UPC_SAN_MIGUEL':
        return 'SAN MIGUEL';
      case 'UPC_VILLA':
        return 'VILLA';
      case 'UNMSM':
        return 'UNMSM';
      default:
        return backendCampus;
    }
  }

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: (json['id'] as num).toInt(),
      leaderId: (json['leaderId'] as num).toInt(),
      startCampus: _mapBackendCampusToApp(json['startCampus'] as String? ?? ''),
      startLocation: LocationModel.fromJson(Map<String, dynamic>.from(json['startLocation'] as Map)),
      destination: LocationModel.fromJson(Map<String, dynamic>.from(json['destination'] as Map)),
      encodedPolyline: json['encodedPolyline'] as String?,
      totalDistanceKm: (json['totalDistanceKm'] as num? ?? 0.0).toDouble(),
      visibility: json['visibility'] as String? ?? 'SEARCHABLE',
      waypoints: json['waypoints'] != null
          ? (json['waypoints'] as List)
              .map((w) => LocationModel.fromJson(Map<String, dynamic>.from(w as Map)))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leaderId': leaderId,
      'startCampus': startCampus,
      'startLocation': (startLocation as LocationModel).toJson(),
      'destination': (destination as LocationModel).toJson(),
      'encodedPolyline': encodedPolyline,
      'totalDistanceKm': totalDistanceKm,
      'visibility': visibility,
      'waypoints': waypoints.map((w) => (w as LocationModel).toJson()).toList(),
    };
  }
}
