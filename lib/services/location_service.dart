// import 'package:geolocator/geolocator.dart';

/// Serviço de localização GPS para o tracking de viagem (spec §6).
///
/// No MVP faz tracking em primeiro plano. Background virá numa fase posterior
/// (exige foreground service nativo — fora do escopo básico).
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Garante que as permissões de localização foram concedidas.
  /// Solicita de forma contextual conforme spec §25.
  ///
  /// Retorna true se pronto para usar.
  Future<bool> ensurePermission() async {
    // TODO: Implementar quando geolocator for reativado
    return true;
  }

  /// Última posição conhecida (rápido, sem aguardar fix de GPS).
  Future<Position?> lastKnownPosition() async {
    // TODO: Implementar quando geolocator for reativado
    return null;
  }

  /// Posição atual com alta precisão.
  Future<Position> currentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    // TODO: Implementar quando geolocator for reativado
    throw UnimplementedError('Geolocator temporariamente desabilitado');
  }

  /// Stream de posições para tracking contínuo (spec §6).
  ///
  /// [distanceFilter] em metros — só emite quando o usuário se move pelo menos
  /// essa distância. Reduz consumo de bateria e volume de dados.
  Stream<Position> positionStream({
    double distanceFilterMeters = 10,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    // TODO: Implementar quando geolocator for reativado
    return Stream.empty();
  }
}

// Classes stub para compatibilidade
class Position {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final double heading;
  final double accuracy;

  Position({
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.speed = 0.0,
    this.heading = 0.0,
    this.accuracy = 0.0,
  });
}

class LocationAccuracy {
  static const high = LocationAccuracy._();
  LocationAccuracy._();
}

class LocationSettings {
  LocationSettings({required LocationAccuracy accuracy, required int distanceFilter});
}

class LocationPermission {}

class LocationServiceDisabledException implements Exception {}
