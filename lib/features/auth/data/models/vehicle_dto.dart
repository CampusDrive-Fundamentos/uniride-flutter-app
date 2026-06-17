class VehicleDto {
  final String type;
  final String name;
  final String licenseNumber;

  VehicleDto({
    required this.type,
    required this.name,
    required this.licenseNumber,
  });

  factory VehicleDto.fromJson(Map<String, dynamic> json) {
    return VehicleDto(
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "type": type,
    "name": name,
    "licenseNumber": licenseNumber,
  };
}
