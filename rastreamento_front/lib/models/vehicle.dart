class Vehicle {
  final int id;
  final String plate;
  final String type;
  final String? name;
  final bool isOnline;
  final String? lastLocation;
  final String? driverName;
  final double? currentVelocity;
  final int? userId;

  const Vehicle({
    required this.id,
    required this.plate,
    required this.type,
    this.name,
    required this.isOnline,
    this.lastLocation,
    this.driverName,
    this.currentVelocity,
    this.userId,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final source = json['object'] is Map<String, dynamic>
        ? json['object'] as Map<String, dynamic>
        : json;

    return Vehicle(
      id: source['id'] ?? source['vehicle_id'] ?? 0,
      plate: (source['plate'] ?? source['placa'] ?? '').toString(),
      type: (source['type'] ?? source['tipo'] ?? 'Veículo').toString(),
      name: (source['name'] ?? source['nome'])?.toString(),
      isOnline: source['is_online'] ?? source['online'] ?? false,
      lastLocation: source['last_location'] ?? source['localizacao'],
      driverName: source['driver_name'] ?? source['motorista'],
      currentVelocity:
          (source['current_velocity'] ?? source['velocidade']) is num
              ? ((source['current_velocity'] ?? source['velocidade']) as num)
                  .toDouble()
              : null,
      userId: source['user_id'],
    );
  }

  Vehicle copyWith({
    int? id,
    String? plate,
    String? type,
    String? name,
    bool? isOnline,
    String? lastLocation,
    String? driverName,
    double? currentVelocity,
    int? userId,
  }) {
    return Vehicle(
      id: id ?? this.id,
      plate: plate ?? this.plate,
      type: type ?? this.type,
      name: name ?? this.name,
      isOnline: isOnline ?? this.isOnline,
      lastLocation: lastLocation ?? this.lastLocation,
      driverName: driverName ?? this.driverName,
      currentVelocity: currentVelocity ?? this.currentVelocity,
      userId: userId ?? this.userId,
    );
  }

  String get displayName {
    final baseName = (name != null && name!.isNotEmpty) ? name! : type;
    return '$baseName - $plate';
  }
}
