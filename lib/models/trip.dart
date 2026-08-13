/// Modelo de Viagem (Trip) — corresponde à tabela `trips` do backend.
///
/// Espelha o ciclo de vida da spec §5:
///   planning -> active -> (paused) -> completed
class Trip {
  final int id;
  final int userId;
  final int? motorcycleId;
  final String? title;
  final String? description;
  final String? startLocation;
  final String? endLocation;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final double distanceKm;
  final int durationSeconds;
  final int movingSeconds;
  final int stoppedSeconds;
  final double? maxSpeed;
  final double? avgSpeed;
  final String trackingMode;
  final String visibility;
  final String status; // planning | active | paused | completed | cancelled | imported
  final String? startTime;
  final String? endTime;
  final String? createdAt;

  Trip({
    required this.id,
    required this.userId,
    this.motorcycleId,
    this.title,
    this.description,
    this.startLocation,
    this.endLocation,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    required this.distanceKm,
    required this.durationSeconds,
    required this.movingSeconds,
    required this.stoppedSeconds,
    this.maxSpeed,
    this.avgSpeed,
    required this.trackingMode,
    required this.visibility,
    required this.status,
    this.startTime,
    this.endTime,
    this.createdAt,
  });

  factory Trip.fromJson(Map<String, dynamic> j) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) {
        
        return double.parse(v);
      }
      
      return 0.0;
    }
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) {
        
        return int.parse(v);
      }
      
      return 0;
    }
    
    return Trip(
      id: toInt(j['id']),
      userId: toInt(j['user_id']),
      motorcycleId: j['motorcycle_id'] == null ? null : toInt(j['motorcycle_id']),
      title: j['title'] as String?,
      description: j['description'] as String?,
      startLocation: j['start_location'] as String?,
      endLocation: j['end_location'] as String?,
      startLat: j['start_lat'] == null ? null : toDouble(j['start_lat']),
      startLng: j['start_lng'] == null ? null : toDouble(j['start_lng']),
      endLat: j['end_lat'] == null ? null : toDouble(j['end_lat']),
      endLng: j['end_lng'] == null ? null : toDouble(j['end_lng']),
      distanceKm: toDouble(j['distance_km']),
      durationSeconds: toInt(j['duration_seconds']),
      movingSeconds: toInt(j['moving_seconds']),
      stoppedSeconds: toInt(j['stopped_seconds']),
      maxSpeed: j['max_speed'] == null ? null : toDouble(j['max_speed']),
      avgSpeed: j['avg_speed'] == null ? null : toDouble(j['avg_speed']),
      trackingMode: j['tracking_mode'] as String? ?? 'normal',
      visibility: j['visibility'] as String? ?? 'private',
      status: j['status'] as String? ?? 'planning',
      startTime: j['start_time'] as String?,
      endTime: j['end_time'] as String?,
      createdAt: j['created_at'] as String?,
    );
  }

  /// True se a viagem está em andamento (spec §4: "viagem em andamento").
  bool get isActive => status == 'active';

  bool get isPaused => status == 'paused';

  bool get isCompleted => status == 'completed';

  /// Tempo total formatado HH:MM (spec §7).
  String get durationFormatted {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Distância formatada em km (spec §7).
  String get distanceFormatted => '${distanceKm.toStringAsFixed(0)} km';

  @override
  String toString() => 'Trip(#$id, $status, $title, ${distanceFormatted})';
}
