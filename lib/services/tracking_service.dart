import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço de tracking em segundo plano.
///
/// Mantém o GPS ativo e envia pontos para o servidor mesmo quando
/// o app é fechado. O serviço roda como um foreground service no Android.
class TrackingService {
  static const _kActiveTripId = 'bg_active_trip_id';
  static const _kApiToken = 'bg_api_token';
  static const _kApiBaseUrl = 'bg_api_base_url';

  /// Inicializa o serviço de background.
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'motohead_tracking',
        initialNotificationTitle: 'MotoHead',
        initialNotificationContent: 'Tracking de viagem ativo',
        foregroundServiceNotificationId: 8888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Inicia o serviço de tracking em background.
  static Future<void> start({
    required int tripId,
    required String token,
    required String apiBaseUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kActiveTripId, tripId);
    await prefs.setString(_kApiToken, token);
    await prefs.setString(_kApiBaseUrl, apiBaseUrl);

    final service = FlutterBackgroundService();
    await service.startService();
  }

  /// Para o serviço de tracking em background.
  static Future<void> stop() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kActiveTripId);

    final service = FlutterBackgroundService();
    service.invoke('stop');
  }

  /// Verifica se o serviço está rodando.
  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  /// Verifica se há uma viagem ativa em background.
  static Future<int?> getActiveTripId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kActiveTripId);
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    final prefs = await SharedPreferences.getInstance();
    final tripId = prefs.getInt(_kActiveTripId);
    final token = prefs.getString(_kApiToken);
    final baseUrl = prefs.getString(_kApiBaseUrl);

    if (tripId == null || token == null || baseUrl == null) {
      service.stopSelf();
      return;
    }

    // Stream de posições GPS
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    final positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );

    final subscription = positionStream.listen((Position position) async {
      // Envia o ponto para o servidor
      try {
        final url = Uri.parse(
          '$baseUrl/api/tracking/trips/$tripId/point',
        );
        await _sendPoint(url, token, position);
      } catch (e) {
        // Erro de rede — continua tentando no próximo ponto
      }
    });

    // Escuta comando de parada
    service.on('stop').listen((event) {
      subscription.cancel();
      service.stopSelf();
    });

    // Mantém o serviço vivo
    service.on('ping').listen((event) {});
  }

  static Future<void> _sendPoint(
    Uri url,
    String token,
    Position pos,
  ) async {
    // Usa dart:io HttpClient para evitar dependência do http no isolote
    final httpClient = HttpClient();
    try {
      final request = await httpClient.postUrl(url);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Accept', 'application/json');

      final body = '''
{
  "lat": ${pos.latitude},
  "lng": ${pos.longitude},
  "altitude": ${pos.altitude},
  "speed": ${pos.speed},
  "heading": ${pos.heading ?? 0},
  "accuracy": ${pos.accuracy},
  "recorded_at": "${DateTime.now().toIso8601String()}"
}''';
      request.write(body);
      await request.close();
    } finally {
      httpClient.close();
    }
  }
}
