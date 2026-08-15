import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Serviço de localização GPS para o tracking de viagem (spec §6).
///
/// Usa GPS de alta precisão (bestForNavigation) para forçar satélite.
/// Filtra coordenadas inválidas (0,0) e saltos irreais (Wi-Fi/IP).
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Distância máxima aceitável entre pontos consecutivos (km).
  /// Saltos maiores que isso indicam salto de Wi-Fi/IP para GPS real.
  static const double _maxJumpKm = 50;

  /// Última posição válida conhecida — usada para detectar saltos irreais.
  Position? _lastValidPosition;

  /// Verifica se as coordenadas são válidas.
  bool _isValidPosition(double lat, double lng) {
    if (lat == 0.0 && lng == 0.0) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    return true;
  }

  /// Verifica se a posição é um salto irreal (Wi-Fi/IP → GPS real).
  /// Se a posição saltou mais de _maxJumpKm do último ponto, é suspeita.
  bool _isRealisticJump(Position pos) {
    if (_lastValidPosition == null) return true;
    final distance = Geolocator.distanceBetween(
      _lastValidPosition!.latitude,
      _lastValidPosition!.longitude,
      pos.latitude,
      pos.longitude,
    );
    // Salto > 50km em poucos segundos é irreal — provavelmente Wi-Fi/IP
    return distance < (_maxJumpKm * 1000);
  }

  /// Garante que as permissões de localização foram concedidas.
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

  /// Posição atual com GPS de alta precisão.
  /// Rejeita coordenadas inválidas (0,0) e tenta obter fix de satélite.
  Future<Position> currentPosition({
    String accuracy = 'high',
  }) async {
    // bestForNavigation força uso de GPS por satélite
    final LocationAccuracy locationAccuracy = accuracy == 'high'
        ? LocationAccuracy.bestForNavigation
        : LocationAccuracy.high;

    // Tenta até 3 vezes obter uma posição válida
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: locationAccuracy,
          timeLimit: const Duration(seconds: 15),
        );

        if (_isValidPosition(pos.latitude, pos.longitude)) {
          _lastValidPosition = pos;
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
    if (lastKnown != null &&
        _isValidPosition(lastKnown.latitude, lastKnown.longitude)) {
      _lastValidPosition = lastKnown;
      return lastKnown;
    }

    throw Exception(
      'Não foi possível obter sua localização. Verifique se o GPS está ativado '
      'e tente novamente ao ar livre.',
    );
  }

  /// Stream de posições para tracking contínuo (spec §6).
  ///
  /// Usa GPS de alta precisão (bestForNavigation) para forçar satélite.
  /// Filtra coordenadas inválidas (0,0) e saltos irreais (Wi-Fi/IP).
  ///
  /// NÃO rejeita por precisão — o TripProvider já tem regras inteligentes
  /// de distância/speed para decidir se grava o ponto.
  Stream<Position> positionStream({
    double distanceFilterMeters = 10,
    String accuracy = 'high',
  }) {
    final LocationAccuracy locationAccuracy = accuracy == 'high'
        ? LocationAccuracy.bestForNavigation
        : LocationAccuracy.high;

    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: locationAccuracy,
        distanceFilter: distanceFilterMeters.toInt(),
      ),
    ).where((pos) {
      // Filtra 0,0 (meio do oceano)
      if (!_isValidPosition(pos.latitude, pos.longitude)) return false;
      // Filtra saltos irreais (Wi-Fi/IP → GPS real)
      if (!_isRealisticJump(pos)) return false;
      // Atualiza última posição válida
      _lastValidPosition = pos;
      return true;
    });
  }
}
