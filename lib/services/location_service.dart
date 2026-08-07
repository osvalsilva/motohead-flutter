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
    // 1. Verifica serviço de localização habilitado no dispositivo.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await Geolocator.openLocationSettings();
      if (!serviceEnabled) return false;
    }

    // 2. Verifica permissão.
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) return false;
    if (perm == LocationPermission.deniedForever) {
      // Abre settings para o usuário habilitar manualmente.
      await Geolocator.openAppSettings();
      return false;
    }
    return true;
  }

  /// Última posição conhecida (rápido, sem aguardar fix de GPS).
  Future<Position?> lastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  /// Posição atual com alta precisão.
  Future<Position> currentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    return Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: accuracy),
    );
  }

  /// Stream de posições para tracking contínuo (spec §6).
  ///
  /// [distanceFilter] em metros — só emite quando o usuário se move pelo menos
  /// essa distância. Reduz consumo de bateria e volume de dados.
  Stream<Position> positionStream({
    double distanceFilterMeters = 10,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters.toInt(),
      ),
    );
  }
}
