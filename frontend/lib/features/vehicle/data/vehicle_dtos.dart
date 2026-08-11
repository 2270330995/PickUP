class VehicleResponse {
  const VehicleResponse({
    required this.id,
    required this.ownerId,
    required this.make,
    required this.model,
    this.color,
    this.plate,
    required this.seats,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String make;
  final String model;
  final String? color;
  final String? plate;
  final int seats;
  final DateTime createdAt;

  String get displayLabel {
    final base = '$make $model';
    final parts = <String>[base];
    if (color != null && color!.isNotEmpty) parts.add(color!);
    if (plate != null && plate!.isNotEmpty) parts.add(plate!);
    return parts.join(' · ');
  }

  factory VehicleResponse.fromJson(Map<String, dynamic> json) {
    return VehicleResponse(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      color: json['color'] as String?,
      plate: json['plate'] as String?,
      seats: (json['seats'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class CreateVehicleRequest {
  const CreateVehicleRequest({
    required this.make,
    required this.model,
    this.color,
    this.plate,
    required this.seats,
  });

  final String make;
  final String model;
  final String? color;
  final String? plate;
  final int seats;

  Map<String, dynamic> toJson() => {
        'make': make,
        'model': model,
        if (color != null && color!.isNotEmpty) 'color': color,
        if (plate != null && plate!.isNotEmpty) 'plate': plate,
        'seats': seats,
      };
}

class UpdateVehicleRequest {
  const UpdateVehicleRequest({
    this.make,
    this.model,
    this.color,
    this.plate,
    this.seats,
  });

  final String? make;
  final String? model;
  final String? color;
  final String? plate;
  final int? seats;

  Map<String, dynamic> toJson() => {
        if (make != null) 'make': make,
        if (model != null) 'model': model,
        if (color != null) 'color': color,
        if (plate != null) 'plate': plate,
        if (seats != null) 'seats': seats,
      };
}
