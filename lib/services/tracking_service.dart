import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_logger.dart';

/// Log do isolate de background — grava no MESMO arquivo de log do app
/// (append é atômico para linhas pequenas). O AppLogger da UI não é
/// compartilhado entre isolates, então o BG precisa escrever direto.
Future<void> _bgLog(String message) async {
  debugPrint('BG_SERVICE: $message');
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/logs/motohead.log');
    await file.parent.create(recursive: true);
    await file.writeAsString(
      '[${DateTime.now().toIso8601String()}] BG_SERVICE: $message\n',
      mode: FileMode.append,
    );
  } catch (_) {}
}

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
  /// NÃO solicita permissão aqui — isso é feito separadamente para evitar
  /// crash quando o Android recria a Activity após conceder a permissão.
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
          foregroundServiceTypes: [AndroidForegroundType.location],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );
      _bgLog('initialize() concluído');
    } catch (e, stack) {
      _bgLog('ERRO no initialize(): $e\n$stack');
    }
  }

  /// Solicita permissão de notificação (Android 13+).
  /// Deve ser chamado cedo no ciclo de vida do app, NÃO durante startTrip().
  static Future<void> requestNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.requestNotificationsPermission();
        }
      }
    } catch (e) {
      _bgLog('Erro ao solicitar permissão de notificação: $e');
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
      _bgLog('Erro ao atualizar notificação: $e');
    }
  }

  /// Inicia o serviço de tracking em background.
  /// NÃO solicita permissão de notificação aqui — isso é feito em
  /// requestNotificationPermission() separadamente para evitar crash.
  static Future<void> start({
    required int tripId,
    required String token,
    required String apiBaseUrl,
  }) async {
    AppLogger.log('BG_SERVICE', '=== start() chamado === tripId=$tripId');
    try {
      final service = FlutterBackgroundService();
      var isRunning = false;
      try {
        isRunning = await service.isRunning();
      } catch (_) {}
      AppLogger.log('BG_SERVICE', 'start: serviço rodando? $isRunning');
      if (!isRunning) {
        AppLogger.log('BG_SERVICE', 'start: configurando serviço...');
        await initialize();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kActiveTripId, tripId);
      await prefs.setString(_kApiToken, token);
      await prefs.setString(_kApiBaseUrl, apiBaseUrl);
      await prefs.setInt(
          _kTripStartTime, DateTime.now().millisecondsSinceEpoch);

      AppLogger.log('BG_SERVICE', 'start: chamando startService()...');
      await service.startService();
      AppLogger.log('BG_SERVICE', 'start: startService() retornou sem erro');

      await _updateNotification(
        distanceKm: 0,
        durationSeconds: 0,
        speedKmh: 0,
      );
      AppLogger.log('BG_SERVICE', '=== start() concluído ===');
    } catch (e, stack) {
      AppLogger.error('BG_SERVICE', 'start: erro: $e', stack: stack.toString());
      _bgLog('ERRO no start(): $e');
    }
  }

  /// Para o serviço de tracking em background.
  static Future<void> stop() async {
    AppLogger.log('BG_SERVICE', '=== stop() chamado ===');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kActiveTripId);
      await prefs.remove(_kTripStartTime);

      final service = FlutterBackgroundService();
      service.invoke('stop');

      // NÃO chamar _notifications.cancel() aqui: além de desnecessário
      // (a notificação do FGS é removida quando o serviço para), o plugin
      // flutter_local_notifications lança "Missing type parameter" ao ler
      // o cache de notificações agendadas corrompido neste dispositivo.
      AppLogger.log('BG_SERVICE', 'stop: serviço parado');
    } catch (e) {
      AppLogger.error('BG_SERVICE', 'stop: erro: $e');
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

    _bgLog('=== onStart() chamado === serviço iniciando');

    final prefs = await SharedPreferences.getInstance();
    final tripId = prefs.getInt(_kActiveTripId);
    final token = prefs.getString(_kApiToken);
    final baseUrl = prefs.getString(_kApiBaseUrl);
    final startTimeMs = prefs.getInt(_kTripStartTime);

    _bgLog('tripId=$tripId, token=${token != null ? "sim" : "não"}, baseUrl=$baseUrl');

    if (tripId == null || token == null || baseUrl == null) {
      _bgLog('Dados incompletos, parando serviço');
      service.stopSelf();
      return;
    }

    _bgLog('tripId=$tripId, iniciando tracking GPS');

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

    // Garante que o GPS tenha permissão antes de iniciar o stream
    try {
      _bgLog('verificando GPS...');
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      _bgLog('GPS ativado? $serviceEnabled');
      if (!serviceEnabled) {
        _bgLog('GPS desativado, serviço não pode continuar');
        _updateNotificationStatic('GPS desativado — tracking pausado');
        return;
      }
      final permission = await Geolocator.checkPermission();
      _bgLog('permissão GPS = $permission');
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _bgLog('Permissão de localização negada');
        _updateNotificationStatic('Permissão de GPS negada — tracking pausado');
        return;
      }
      _bgLog('GPS OK, iniciando stream...');
    } catch (e) {
      _bgLog('Erro ao verificar permissão GPS: $e');
    }

    // Stream de posições GPS — sem distanceFilter, grava todos os pontos
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      timeLimit: Duration(seconds: 30),
    );

    StreamSubscription<Position>? subscription;
    int pointCount = 0;
    try {
      _bgLog('criando stream de GPS...');
      final positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      );
      _bgLog('stream criado, escutando...');

      subscription = positionStream.listen((Position position) async {
        if (position.latitude == 0.0 && position.longitude == 0.0) return;

        pointCount++;
        _bgLog('Ponto #$pointCount - ${position.latitude}, ${position.longitude} speed=${(position.speed * 3.6).toStringAsFixed(1)}km/h');

        currentSpeedKmh = position.speed * 3.6;

        if (lastLat != 0.0 && lastLng != 0.0) {
          final meters =
              _haversine(lastLat, lastLng, position.latitude, position.longitude);
          if (meters > 0) {
            totalDistanceKm += meters / 1000.0;
          }
        }

        lastLat = position.latitude;
        lastLng = position.longitude;

        final elapsed = DateTime.now().difference(startTime).inSeconds;
        await _updateNotification(
          distanceKm: totalDistanceKm,
          durationSeconds: elapsed,
          speedKmh: currentSpeedKmh,
        );

        try {
          final url = Uri.parse('$baseUrl/api/tracking/trips/$tripId/point');
          await _sendPoint(url, token, position);
          _bgLog('Ponto #$pointCount enviado ao servidor');
        } catch (e) {
          _bgLog('Erro de rede ao enviar ponto #$pointCount: $e');
        }
      }, onError: (e) {
        _bgLog('Erro no stream de GPS: $e');
      });
    } catch (e) {
      _bgLog('Erro ao iniciar stream de GPS: $e');
    }

    // Escuta comando de parada
    service.on('stop').listen((event) {
      _bgLog('comando stop recebido — parando serviço');
      subscription?.cancel();
      notifTimer?.cancel();
      service.stopSelf();
    });

    // Mantém o serviço vivo
    service.on('ping').listen((event) {
      _bgLog('ping recebido');
    });
    _bgLog('onStart() concluído — serviço ativo e escutando GPS');
  }

  /// Notificação estática simples (para mensagens de erro/status)
  static Future<void> _updateNotificationStatic(String message) async {
    try {
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

      await _notifications.show(
        _notificationId,
        'MotoHead — Viagem',
        message,
        const NotificationDetails(android: androidDetails),
      );
    } catch (_) {}
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
  "heading": ${pos.heading},
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
