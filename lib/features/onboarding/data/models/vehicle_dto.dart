class VehicleDto {
  final String model;
  final String color;
  final String plate;

  VehicleDto({required this.model, required this.color, required this.plate});

  Map<String, dynamic> toJson() => {
    "model": model,
    "color": color,
    "plate": plate,
  };
}