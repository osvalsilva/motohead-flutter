import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço de tracking em segundo plano.
///
/// Mantém o GPS ativo e envia pontos para o servidor mesmo quando
/// o app é fechado. Mostra uma notificação visível na tela de bloqueio
/// com quilometragem e tempo de viagem em tempo real.
class TrackingService {
  static const _kActiveTripId = 'bg_active_trip_id';
  static const _kApiToken = 'bg_api_token';
  static const _kApiBaseUrl = 'bg_api_base_url';
  static const _kTripStartTime = 'bg_trip_start_time';

  static const _notificationChannelId = 'motohead_tracking';
  static const _notificationId = 8888;

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Inicializa o serviço de background e o canal de notificação.
  /// Seguro para chamar no main() — não lança exceções.
  static Future<void> initialize() async {
    try {
      // Inicializa notificações locais
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      await _notifications.initialize(
        const InitializationSettings(
            android: androidSettings, iOS: iosSettings),
      );

      // Solicita permissão de notificação (Android 13+ exige em tempo de execução)
      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          // requestNotificationsPermission() retorna true se concedida
          await androidPlugin.requestNotificationsPermission();
        }
      }

      // Cria canal de notificação visível na tela de bloqueio
      const channel = AndroidNotificationChannel(
        _notificationChannelId,
        'MotoHead Tracking',
        description: 'Notificação de tracking de viagem ativa',
        importance: Importance.high,
        enableVibration: false,
        playSound: false,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      final service = FlutterBackgroundService();

      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: _notificationChannelId,
          initialNotificationTitle: 'MotoHead — Viagem em andamento',
          initialNotificationContent: 'Iniciando tracking...',
          foregroundServiceNotificationId: _notificationId,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );
    } catch (e) {
      debugPrint('Erro ao inicializar tracking service: $e');
    }
  }

  /// Atualiza a notificação com quilometragem e tempo atuais.
  static Future<void> _updateNotification({
    required double distanceKm,
    required int durationSeconds,
    required double speedKmh,
  }) async {
    try {
      final h = durationSeconds ~/ 3600;
      final m = (durationSeconds % 3600) ~/ 60;
      final s = durationSeconds % 60;
      final timeStr =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

      final content =
          'Tempo: $timeStr  |  Dist: ${distanceKm.toStringAsFixed(2)} km  |  Vel: ${speedKmh.toStringAsFixed(0)} km/h';

      const androidDetails = AndroidNotificationDetails(
        _notificationChannelId,
        'MotoHead Tracking',
        channelDescription: 'Notificação de tracking de viagem ativa',
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        ongoing: true,
        showWhen: false,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      await _notifications.show(
        _notificationId,
        'MotoHead — Viagem em andamento',
        content,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (e) {
      // Ignora erro de notificação — não afeta o tracking
    }
  }

  /// Inicia o serviço de tracking em background.
  static Future<void> start({
    required int tripId,
    required String token,
    required String apiBaseUrl,
  }) async {
    try {
      // Garante que o serviço foi configurado (se não foi ainda)
      final service = FlutterBackgroundService();
      var isRunning = false;
      try {
        isRunning = await service.isRunning();
      } catch (_) {}
      if (!isRunning) {
        await initialize();
      }

      // Solicita permissão de notificação novamente (Android 13+)
      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.requestNotificationsPermission();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kActiveTripId, tripId);
      await prefs.setString(_kApiToken, token);
      await prefs.setString(_kApiBaseUrl, apiBaseUrl);
      await prefs.setInt(
          _kTripStartTime, DateTime.now().millisecondsSinceEpoch);

      await service.startService();

      // Mostra notificação imediatamente
      await _updateNotification(
        distanceKm: 0,
        durationSeconds: 0,
        speedKmh: 0,
      );
    } catch (e) {
      debugPrint('Erro ao iniciar tracking service: $e');
    }
  }

  /// Para o serviço de tracking em background.
  static Future<void> stop() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kActiveTripId);
      await prefs.remove(_kTripStartTime);

      final service = FlutterBackgroundService();
      service.invoke('stop');

      await _notifications.cancel(_notificationId);
    } catch (e) {
      debugPrint('Erro ao parar tracking service: $e');
    }
  }

  /// Verifica se o serviço está rodando.
  static Future<bool> isRunning() async {
    try {
      final service = FlutterBackgroundService();
      return await service.isRunning();
    } catch (_) {
      return false;
    }
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
    final startTimeMs = prefs.getInt(_kTripStartTime);

    if (tripId == null || token == null || baseUrl == null) {
      service.stopSelf();
      return;
    }

    // Estado local do tracking
    double totalDistanceKm = 0;
    double lastLat = 0;
    double lastLng = 0;
    double currentSpeedKmh = 0;
    final startTime = startTimeMs != null
        ? DateTime.fromMillisecondsSinceEpoch(startTimeMs)
        : DateTime.now();

    // Timer para atualizar a notificação a cada segundo
    Timer? notifTimer;
    notifTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      _updateNotification(
        distanceKm: totalDistanceKm,
        durationSeconds: elapsed,
        speedKmh: currentSpeedKmh,
      );
    });

    // Stream de posições GPS
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    final positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );

    final subscription = positionStream.listen((Position position) async {
      // Rejeita coordenadas inválidas (0,0 = meio do oceano)
      if (position.latitude == 0.0 && position.longitude == 0.0) return;

      currentSpeedKmh = position.speed * 3.6;

      // Regras inteligentes para contagem de pontos
      bool shouldRecord = true;
      if (lastLat != 0.0 && lastLng != 0.0) {
        final meters =
            _haversine(lastLat, lastLng, position.latitude, position.longitude);

        // Parado — não conta
        if (currentSpeedKmh < 2) {
          shouldRecord = false;
        } else if (currentSpeedKmh < 30) {
          // Baixa velocidade: a cada 10m
          shouldRecord = meters >= 10;
        } else if (currentSpeedKmh < 80) {
          // Média velocidade: a cada 50m
          shouldRecord = meters >= 50;
        } else {
          // Alta velocidade: a cada 150m
          shouldRecord = meters >= 150;
        }

        if (shouldRecord && meters > 0) {
          totalDistanceKm += meters / 1000.0;
        }
      }

      lastLat = position.latitude;
      lastLng = position.longitude;

      // Atualiza notificação com dados atuais
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      _updateNotification(
        distanceKm: totalDistanceKm,
        durationSeconds: elapsed,
        speedKmh: currentSpeedKmh,
      );

      // Envia o ponto apenas se passou nas regras
      if (shouldRecord) {
        try {
          final url = Uri.parse('$baseUrl/api/tracking/trips/$tripId/point');
          await _sendPoint(url, token, position);
        } catch (e) {
          // Erro de rede — continua tentando no próximo ponto
        }
      }
    });

    // Escuta comando de parada
    service.on('stop').listen((event) {
      subscription.cancel();
      notifTimer?.cancel();
      service.stopSelf();
    });

    // Mantém o serviço vivo
    service.on('ping').listen((event) {});
  }

  /// Fórmula de Haversine para cálculo de distância entre dois pontos.
  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // metros
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double deg) => deg * (math.pi / 180);

  static Future<void> _sendPoint(
    Uri url,
    String token,
    Position pos,
  ) async {
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
