import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Serviço de localização GPS para o tracking de viagem.
///
/// Usa GPS de alta precisão. Filtra apenas coordenadas 0,0.
/// As regras de gravação de pontos ficam no TripProvider.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Verifica se as coordenadas são válidas.
  bool _isValidPosition(double lat, double lng) {
    if (lat == 0.0 && lng == 0.0) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    return true;
  }

  /// Garante que as permissões de localização foram concedidas.
  Future<bool> ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[GPS] Serviço de localização desativado');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[GPS] Permissão negada');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[GPS] Permissão negada permanentemente');
      return false;
    }

    debugPrint('[GPS] Permissão concedida');
    return true;
  }

  /// Última posição conhecida.
  Future<Position?> lastKnownPosition() async {
    return await Geolocator.getLastKnownPosition();
  }

  /// Posição atual com GPS de alta precisão.
  Future<Position> currentPosition({
    String accuracy = 'high',
  }) async {
    final LocationAccuracy locationAccuracy = accuracy == 'high'
        ? LocationAccuracy.bestForNavigation
        : LocationAccuracy.high;

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        debugPrint('[GPS] Tentativa ${attempt + 1} de obter posição...');
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: locationAccuracy,
          timeLimit: const Duration(seconds: 15),
        );
        debugPrint('[GPS] Posição obtida: ${pos.latitude}, ${pos.longitude} (acc: ${pos.accuracy}m, speed: ${pos.speed}m/s)');

        if (_isValidPosition(pos.latitude, pos.longitude)) {
          return pos;
        }
        debugPrint('[GPS] Coordenadas inválidas (0,0) — tentando novamente');
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('[GPS] Erro: $e');
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    // Tenta última posição conhecida
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null && _isValidPosition(lastKnown.latitude, lastKnown.longitude)) {
      debugPrint('[GPS] Usando última posição conhecida: ${lastKnown.latitude}, ${lastKnown.longitude}');
      return lastKnown;
    }

    throw Exception(
      'Não foi possível obter sua localização. Verifique se o GPS está ativado.',
    );
  }

  /// Stream de posições para tracking contínuo.
  ///
  /// SEM distanceFilter — emite todas as posições do GPS.
  /// O TripProvider decide quais pontos gravar baseado em distância/speed.
  /// Filtra apenas coordenadas 0,0 (meio do oceano).
  Stream<Position> positionStream({
    double distanceFilterMeters = 0,
    String accuracy = 'high',
  }) {
    final LocationAccuracy locationAccuracy = accuracy == 'high'
        ? LocationAccuracy.bestForNavigation
        : LocationAccuracy.high;

    debugPrint('[GPS] Iniciando stream (accuracy: $locationAccuracy, distanceFilter: $distanceFilterMeters m)');

    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: locationAccuracy,
        distanceFilter: distanceFilterMeters.toInt(),
      ),
    ).where((pos) {
      // Filtra apenas 0,0 — TODO o resto passa para o TripProvider decidir
      final valid = _isValidPosition(pos.latitude, pos.longitude);
      if (!valid) {
        debugPrint('[GPS Stream] Posição rejeitada: 0,0');
      }
      return valid;
    });
  }
}
