class LocationPoint {
  final int vehicleId;
  final double latitude;
  final double longitude;
  final double? velocity;
  final String? status;
  final String? localizacao;
  final DateTime timestamp;
  final String? rawTimestamp;

  LocationPoint({
    required this.vehicleId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.velocity,
    this.status,
    this.localizacao,
    this.rawTimestamp,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    final source = json['object'] is Map<String, dynamic>
        ? json['object'] as Map<String, dynamic>
        : json;

    double? toDoubleValue(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    DateTime parseDateValue(dynamic value) {
      if (value is DateTime) return value.toLocal();
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed.toLocal();
        }
      }
      return DateTime.now().toLocal();
    }

    return LocationPoint(
      vehicleId: source['vehicle_id'] ?? source['id'] ?? 0,
      latitude: toDoubleValue(source['latitude']) ?? 0,
      longitude: toDoubleValue(source['longitude']) ?? 0,
      velocity: toDoubleValue(source['velocity'] ?? source['velocidade']),
      status: source['status'],
      localizacao: source['localizacao'] ?? source['last_location'],
      timestamp: parseDateValue(source['timestamp']),
      rawTimestamp: source['timestamp']?.toString(),
    );
  }

  DateTime get localTimestamp => timestamp.toLocal();
  String get displayTimestamp => rawTimestamp ?? localTimestamp.toString();
}
