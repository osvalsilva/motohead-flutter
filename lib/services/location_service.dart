import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'app_logger.dart';

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
  /// Solicita permissão de segundo plano se necessário (Android 10+).
  Future<bool> ensurePermission() async {
    AppLogger.log('GPS', 'ensurePermission: verificando se GPS está ativado...');
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.error('GPS', 'ensurePermission: serviço de localização desativado');
      return false;
    }
    AppLogger.log('GPS', 'ensurePermission: serviço GPS ativo');

    AppLogger.log('GPS', 'ensurePermission: verificando permissão atual...');
    LocationPermission permission = await Geolocator.checkPermission();
    AppLogger.log('GPS', 'ensurePermission: permissão atual = $permission');

    if (permission == LocationPermission.denied) {
      AppLogger.log('GPS', 'ensurePermission: solicitando permissão...');
      permission = await Geolocator.requestPermission();
      AppLogger.log('GPS', 'ensurePermission: após solicitação = $permission');
      if (permission == LocationPermission.denied) {
        AppLogger.error('GPS', 'ensurePermission: permissão negada');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      AppLogger.error('GPS', 'ensurePermission: permissão negada permanentemente — abrindo configurações');
      return false;
    }

    // Solicita permissão de localização em segundo plano (Android 10+)
    if (!kIsWeb && Platform.isAndroid) {
      AppLogger.log('GPS', 'ensurePermission: verificando permissão de segundo plano...');
      try {
        // Após garantir permissão em primeiro plano, solicita segundo plano
        final bgPermission = await Geolocator.checkPermission();
        if (bgPermission != LocationPermission.always) {
          AppLogger.log('GPS', 'ensurePermission: permissão atual é $bgPermission, solicitando sempre (background)...');
          // No Android 10+, requestPermission pergunta sobre segundo plano
          // se ACCESS_BACKGROUND_LOCATION estiver no manifest
          final newPerm = await Geolocator.requestPermission();
          AppLogger.log('GPS', 'ensurePermission: permissão após solicitação background = $newPerm');
        }
      } catch (e) {
        AppLogger.error('GPS', 'ensurePermission: erro ao verificar background permission: $e');
      }
    }

    AppLogger.info('GPS', 'Permissão concedida');
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
        AppLogger.log('GPS', 'Tentativa ${attempt + 1} de obter posição...');
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: locationAccuracy,
          timeLimit: const Duration(seconds: 15),
        );
        AppLogger.log('GPS', 'Posição obtida: ${pos.latitude}, ${pos.longitude} (acc: ${pos.accuracy}m, speed: ${pos.speed}m/s)');

        if (_isValidPosition(pos.latitude, pos.longitude)) {
          return pos;
        }
        AppLogger.log('GPS', 'Coordenadas inválidas (0,0) — tentando novamente');
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        AppLogger.error('GPS', 'Erro ao obter posição: $e');
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    // Tenta última posição conhecida
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null && _isValidPosition(lastKnown.latitude, lastKnown.longitude)) {
      AppLogger.log('GPS', 'Usando última posição conhecida: ${lastKnown.latitude}, ${lastKnown.longitude}');
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

    AppLogger.log('GPS', 'Iniciando stream (accuracy: $locationAccuracy, distanceFilter: $distanceFilterMeters m)');

    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: locationAccuracy,
        distanceFilter: distanceFilterMeters.toInt(),
      ),
    ).where((pos) {
      // Filtra apenas 0,0 — todo o resto passa para o TripProvider decidir
      final valid = _isValidPosition(pos.latitude, pos.longitude);
      if (!valid) {
        AppLogger.log('GPS', 'Stream: posição rejeitada (0,0)');
      }
      return valid;
    });
  }
}
