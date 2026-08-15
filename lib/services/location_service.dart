import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Serviço de localização GPS para o tracking de viagem (spec §6).
///
/// Força uso de GPS por satélite (não Wi-Fi/IP) para precisão real.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Precisão mínima aceitável em metros.
  /// Posições com precisão pior que isso são rejeitadas (provavelmente Wi-Fi/IP).
  static const double _maxAccuracyMeters = 100;

  /// Verifica se as coordenadas são válidas.
  bool _isValidPosition(double lat, double lng) {
    if (lat == 0.0 && lng == 0.0) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    return true;
  }

  /// Verifica se a posição tem precisão suficiente (não é Wi-Fi/IP).
  bool _isAccurateEnough(Position pos) {
    // Se accuracy for 0 ou negativo, não confiamos
    if (pos.accuracy <= 0) return false;
    // Se accuracy for pior que _maxAccuracyMeters, provavelmente é Wi-Fi/IP
    if (pos.accuracy > _maxAccuracyMeters) return false;
    return true;
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

  /// Posição atual com GPS por satélite (alta precisão).
  ///
  /// Rejeita:
  /// - Coordenadas 0,0 (meio do oceano)
  /// - Posições com baixa precisão (Wi-Fi/IP — provedor de internet)
  ///
  /// Tenta várias vezes até obter um fix real de GPS.
  Future<Position> currentPosition({
    String accuracy = 'high',
  }) async {
    // bestForNavigation força uso de GPS por satélite
    final LocationAccuracy locationAccuracy =
        accuracy == 'high' ? LocationAccuracy.bestForNavigation : LocationAccuracy.high;

    // Tenta até 5 vezes obter uma posição precisa de GPS
    for (int attempt = 0; attempt < 5; attempt++) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: locationAccuracy,
          timeLimit: const Duration(seconds: 20),
        );

        if (_isValidPosition(pos.latitude, pos.longitude) && _isAccurateEnough(pos)) {
          return pos;
        }

        // Posição imprecisa (Wi-Fi/IP) ou inválida — espera e tenta novamente
        // GPS precisa de tempo para conectar aos satélites
        await Future.delayed(const Duration(seconds: 3));
      } catch (e) {
        // Timeout ou erro — tenta novamente
        await Future.delayed(const Duration(seconds: 3));
      }
    }

    // Última tentativa: aceita qualquer posição válida mesmo que imprecisa
    // (melhor que nada para mostrar no mapa)
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      if (_isValidPosition(pos.latitude, pos.longitude)) {
        return pos;
      }
    } catch (_) {}

    // Tenta última posição conhecida
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null && _isValidPosition(lastKnown.latitude, lastKnown.longitude)) {
      return lastKnown;
    }

    throw Exception(
      'Não foi possível obter sua localização por GPS. '
      'Verifique se o GPS está ativado e tente novamente ao ar livre.',
    );
  }

  /// Stream de posições para tracking contínuo (spec §6).
  ///
  /// Usa GPS de alta precisão (bestForNavigation) para forçar satélite.
  /// Filtra coordenadas inválidas e posições imprecisas (Wi-Fi/IP).
  Stream<Position> positionStream({
    double distanceFilterMeters = 10,
    String accuracy = 'high',
  }) {
    final LocationAccuracy locationAccuracy =
        accuracy == 'high' ? LocationAccuracy.bestForNavigation : LocationAccuracy.high;

    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: locationAccuracy,
        distanceFilter: distanceFilterMeters.toInt(),
      ),
    ).where((pos) =>
        _isValidPosition(pos.latitude, pos.longitude) && _isAccurateEnough(pos));
  }
}
