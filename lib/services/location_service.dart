import 'package:geolocator/geolocator.dart';

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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Última posição conhecida (rápido, sem aguardar fix de GPS).
  Future<Position?> lastKnownPosition() async {
    return await Geolocator.getLastKnownPosition();
  }

  /// Posição atual com alta precisão.
  Future<Position> currentPosition({
    String accuracy = 'high',
  }) async {
    LocationAccuracy locationAccuracy = accuracy == 'high'
        ? LocationAccuracy.high
        : LocationAccuracy.medium;
    
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: locationAccuracy,
    );
  }

  /// Stream de posições para tracking contínuo (spec §6).
  ///
  /// [distanceFilter] em metros — só emite quando o usuário se move pelo menos
  /// essa distância. Reduz consumo de bateria e volume de dados.
  Stream<Position> positionStream({
    double distanceFilterMeters = 10,
    String accuracy = 'high',
  }) {
    LocationAccuracy locationAccuracy = accuracy == 'high'
        ? LocationAccuracy.high
        : LocationAccuracy.medium;

    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: locationAccuracy,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }
}