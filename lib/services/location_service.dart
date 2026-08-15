import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Serviço de localização GPS para o tracking de viagem (spec §6).
///
/// No MVP faz tracking em primeiro plano. Background virá numa fase posterior
/// (exige foreground service nativo — fora do escopo básico).
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Verifica se as coordenadas são válidas (não são 0,0 — meio do oceano).
  bool _isValidPosition(double lat, double lng) {
    // Rejeita 0,0 (Null Island — meio do oceano Atlântico)
    if (lat == 0.0 && lng == 0.0) return false;
    // Rejeita coordenadas fora dos limites válidos
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    return true;
  }

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
  /// Rejeita coordenadas inválidas (0,0 = meio do oceano).
  /// Tenta várias vezes até obter uma posição válida (GPS precisa de tempo para fix).
  Future<Position> currentPosition({
    String accuracy = 'high',
  }) async {
    LocationAccuracy locationAccuracy = accuracy == 'high'
        ? LocationAccuracy.high
        : LocationAccuracy.medium;

    // Tenta até 3 vezes obter uma posição válida
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: locationAccuracy,
          timeLimit: const Duration(seconds: 15),
        );

        if (_isValidPosition(pos.latitude, pos.longitude)) {
          return pos;
        }
        // Coordenadas inválidas (0,0) — espera e tenta novamente
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        // Timeout ou erro — tenta novamente
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    // Tenta última posição conhecida
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null && _isValidPosition(lastKnown.latitude, lastKnown.longitude)) {
      return lastKnown;
    }

    // Se tudo falhar, lança erro claro
    throw Exception(
      'Não foi possível obter sua localização. Verifique se o GPS está ativado '
      'e tente novamente ao ar livre.',
    );
  }

  /// Stream de posições para tracking contínuo (spec §6).
  ///
  /// [distanceFilter] em metros — só emite quando o usuário se move pelo menos
  /// essa distância. Reduz consumo de bateria e volume de dados.
  ///
  /// Filtra coordenadas inválidas (0,0 = meio do oceano).
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
        distanceFilter: distanceFilterMeters.toInt(),
      ),
    ).where((pos) => _isValidPosition(pos.latitude, pos.longitude));
  }
}
