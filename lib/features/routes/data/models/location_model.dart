import '../../domain/entities/location.dart';

class LocationModel extends LocationEntity {
  const LocationModel({
    required super.latitude,
    required super.longitude,
    required super.address,
    super.passengerId,
    super.distanceFromStartKm,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String? ?? '',
      passengerId: json['passengerId'] != null ? (json['passengerId'] as num).toInt() : null,
      distanceFromStartKm: json['distanceFromStartKm'] != null 
          ? (json['distanceFromStartKm'] as num).toDouble() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'passengerId': passengerId,
      'distanceFromStartKm': distanceFromStartKm,
    };
  }
}
