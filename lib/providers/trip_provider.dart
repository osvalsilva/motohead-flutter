import 'dart:async';
import 'dart:math' as _math;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/trip.dart';
import '../services/api_service.dart';
import '../services/app_logger.dart';
import '../services/location_service.dart';
import '../services/tracking_service.dart';
import '../config/app_config.dart';

/// Estado da viagem ativa + tracking GPS (spec §5, §6, §8).
///
/// No MVP:
/// - start: cria a trip no servidor e começa a escutar GPS.
/// - pause/resume: pausa o stream localmente (sem endpoint ainda — gap do backend).
/// - finish: para o stream e finaliza no servidor.
/// - pontos são enviados um-a-um via /api/tracking/trips/{id}/point.
class TripProvider extends ChangeNotifier with WidgetsBindingObserver {
  final _api = ApiService.instance;
  final _location = LocationService.instance;

  TripProvider() {
    // Registra como observer para detectar quando o app volta do background
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {
      // Ignora se o binding não estiver pronto
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.log('TRACKING', '=== AppLifecycleState: $state === activeTrip=${_activeTrip?.id}, paused=$_paused, tracking=$_tracking');
    if (state == AppLifecycleState.resumed && _activeTrip != null && !_paused) {
      AppLogger.log('TRACKING', 'App voltou do background — reiniciando tracking');
      if (_tripStartTime != null) {
        _totalDurationSeconds = DateTime.now().difference(_tripStartTime!).inSeconds;
      }
      if (_ticker == null || !_ticker!.isActive) {
        AppLogger.log('TRACKING', 'Ticker parado — reiniciando');
        _startTicker();
      }
      _sub?.cancel();
      _sub = null;
      _startStream();
      _syncStatsFromServer();
      notifyListeners();
    } else if (state == AppLifecycleState.paused && _activeTrip != null && !_paused) {
      AppLogger.log('TRACKING', 'App em background — tracking deve continuar via background service');
    } else if (state == AppLifecycleState.detached) {
      AppLogger.log('TRACKING', 'App sendo destruído pelo sistema');
    }
  }

  /// Sincroniza distância e duração com o servidor após voltar do background.
  Future<void> _syncStatsFromServer() async {
    if (_activeTrip == null) return;
    try {
      final data = await _api.getTripDetails(_activeTrip!.id, pointsLimit: 1);
      final tripData = data['trip'] ?? data;
      final dist = tripData['distance_km'];
      final dur = tripData['duration_seconds'];
      if (dist != null) {
        _currentDistanceKm = (dist is num) ? dist.toDouble() : double.tryParse(dist.toString()) ?? _currentDistanceKm;
      }
      if (dur != null) {
        final d = (dur is num) ? dur.toInt() : int.tryParse(dur.toString()) ?? _totalDurationSeconds;
        if (d > _totalDurationSeconds) _totalDurationSeconds = d;
      }
      notifyListeners();
      AppLogger.log('TRACKING', 'Sincronizado do servidor: dist=${_currentDistanceKm.toStringAsFixed(2)}km, dur=${_totalDurationSeconds}s');
    } catch (e) {
      AppLogger.error('TRACKING', 'Erro ao sincronizar do servidor: $e');
    }
  }

  bool _loading = false;
  bool _tracking = false;
  bool _paused = false;
  Trip? _activeTrip;
  List<Trip> _history = [];
  String? _error;
  bool _isStartingTrip = false; // Flag para evitar chamadas simultâneas

  // Estatísticas locais (espelhando o backend).
  double _currentDistanceKm = 0;
  int _movingSeconds = 0;
  int _totalDurationSeconds = 0; // Duração total da viagem (incluindo paradas)
  double _currentSpeed = 0;
  double? _lastLat;       // Última posição recebida do GPS (para o mapa)
  double? _lastLng;
  double? _lastSentLat;   // Última posição gravada/enviada (para cálculo de distância)
  double? _lastSentLng;
  DateTime? _lastPointAt;
  DateTime? _tripStartTime; // Quando a viagem foi iniciada
  StreamSubscription<Position>? _sub;
  Timer? _ticker; // Timer que continua em background (diferente do Ticker do Flutter)

  // Pontos da rota para traçado em tempo real no mapa
  final List<LatLng> _routePoints = [];
  List<LatLng> get routePoints => List.unmodifiable(_routePoints);

  bool get loading => _loading;
  bool get tracking => _tracking;
  bool get paused => _paused;
  bool get hasActiveTrip => _activeTrip != null && _activeTrip!.isActive;
  Trip? get activeTrip => _activeTrip;
  List<Trip> get history => _history;
  String? get error => _error;

  double get currentDistanceKm => _currentDistanceKm;
  int get movingSeconds => _movingSeconds;
  int get totalDurationSeconds => _totalDurationSeconds;
  double get currentSpeed => _currentSpeed;
  double? get lastLat => _lastLat;
  double? get lastLng => _lastLng;

  /// Carrega histórico de viagens do usuário.
  Future<void> loadHistory() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _history = await _api.listTrips();
      // Detecta viagem ativa no servidor.
      final active = _history.firstWhereOrNull((t) => t.isActive);
      if (active != null) {
        _activeTrip = active;
        // Restaura contadores do servidor para não mostrar 0.0
        _currentDistanceKm = active.distanceKm;
        _totalDurationSeconds = active.durationSeconds;
        _movingSeconds = active.movingSeconds;
        // Calcula _tripStartTime a partir da durationSeconds do servidor
        // (evita problema de fuso horário entre servidor e celular)
        _tripStartTime = DateTime.now().subtract(Duration(seconds: active.durationSeconds));
        AppLogger.log('TRACKING', 'Viagem ativa restaurada — duração: ${active.durationSeconds}s, distância: ${active.distanceKm}km');
        notifyListeners();
        // Inicia o stream de GPS para a viagem ativa
        try {
          final ok = await _location.ensurePermission();
          if (ok) {
            _startStream();
            _startTicker();
            // Carrega a posição atual para o mapa
            try {
              final pos = await _location.currentPosition();
              _lastLat = pos.latitude;
              _lastLng = pos.longitude;
              notifyListeners();
            } catch (_) {
              // GPS não disponível agora — contadores já foram restaurados
            }
          }
        } on UnimplementedError catch (e) {
          // Geolocator desabilitado no web, não impede o carregamento
          print('Geolocator desabilitado no web: $e');
        } catch (e) {
          print('Erro ao iniciar GPS: $e');
        }
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Falha ao carregar viagens: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Inicia uma nova viagem (spec §5: PLANEJADA -> INICIADA -> EM ANDAMENTO).
  Future<bool> startTrip({
    required String name,
    int? motorcycleId,
  }) async {
    if (_isStartingTrip) {
      AppLogger.log('TRACKING', 'startTrip: já iniciando — ignorando chamada simultânea');
      return false;
    }
    _isStartingTrip = true;
    
    AppLogger.log('TRACKING', '=== startTrip() chamado === name="$name", motorcycleId=$motorcycleId');
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Verifica permissão de GPS — pode causar recriação da Activity no Android
      AppLogger.log('TRACKING', 'startTrip: verificando permissão GPS...');
      final ok = await _location.ensurePermission();
      AppLogger.log('TRACKING', 'startTrip: ensurePermission retornou $ok');
      if (!ok) {
        _error = 'Permissão de localização negada. Ative o GPS nas configurações do dispositivo.';
        _loading = false;
        notifyListeners();
        AppLogger.error('TRACKING', 'startTrip: permissão negada — abortando');
        return false;
      }

      // Posição atual do GPS
      AppLogger.log('TRACKING', 'startTrip: obtendo posição GPS atual...');
      Position pos;
      try {
        pos = await _location.currentPosition();
        AppLogger.log('TRACKING', 'startTrip: posição obtida: ${pos.latitude}, ${pos.longitude}');
      } catch (e) {
        AppLogger.error('TRACKING', 'startTrip: erro ao obter posição: $e');
        _error = 'Não foi possível obter sua localização. Verifique se o GPS está ativado.';
        _loading = false;
        notifyListeners();
        return false;
      }

      // Validação extra: não inicia viagem com coordenadas inválidas
      if (pos.latitude == 0.0 && pos.longitude == 0.0) {
        AppLogger.error('TRACKING', 'startTrip: coordenadas inválidas (0,0)');
        _error = 'GPS retornou coordenadas inválidas. Verifique se o GPS está ativado.';
        _loading = false;
        notifyListeners();
        return false;
      }

      AppLogger.log('TRACKING', 'startTrip: chamando API startTrip...');
      final trip = await _api.startTrip(
        name: name,
        motorcycleId: motorcycleId,
        startLat: pos.latitude,
        startLng: pos.longitude,
      );
      AppLogger.log('TRACKING', 'startTrip: API retornou trip id=${trip.id}, status=${trip.status}');
      _activeTrip = trip;
      _currentDistanceKm = 0;
      _movingSeconds = 0;
      _totalDurationSeconds = 0;
      _currentSpeed = 0;
      _lastLat = pos.latitude;
      _lastLng = pos.longitude;
      _lastSentLat = null;
      _lastSentLng = null;
      _lastPointAt = DateTime.now();
      _tripStartTime = DateTime.now();
      AppLogger.log('TRACKING', 'Viagem iniciada — start_time local: $_tripStartTime');
      _paused = false;
      _routePoints.clear();
      _routePoints.add(LatLng(pos.latitude, pos.longitude));
      notifyListeners();

      // Envia o primeiro ponto.
      AppLogger.log('TRACKING', 'startTrip: enviando primeiro ponto...');
      await _sendPoint(pos);

      // Começa o stream de tracking.
      AppLogger.log('TRACKING', 'startTrip: iniciando stream GPS...');
      _startStream();
      // Começa o ticker de duração.
      AppLogger.log('TRACKING', 'startTrip: iniciando ticker...');
      _startTicker();
      // Inicia o serviço de background (continua tracking ao fechar o app)
      if (!kIsWeb) {
        AppLogger.log('TRACKING', 'startTrip: iniciando background service...');
        try {
          await TrackingService.start(
            tripId: trip.id,
            token: _api.token ?? '',
            apiBaseUrl: AppConfig.apiBaseUrl,
          );
          AppLogger.log('TRACKING', 'startTrip: background service iniciado com sucesso');
        } catch (e) {
          AppLogger.error('TRACKING', 'startTrip: erro ao iniciar background service: $e');
        }
      }
      AppLogger.log('TRACKING', '=== startTrip() concluído com sucesso ===');
      return true;
    } on UnimplementedError catch (e) {
      AppLogger.error('TRACKING', 'startTrip: UnimplementedError: $e');
      _error = 'Geolocator temporariamente desabilitado. Verifique se o GPS está ativado nas configurações do navegador.';
      _loading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      AppLogger.error('TRACKING', 'startTrip: ApiException: ${e.message}');
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e, stack) {
      AppLogger.error('TRACKING', 'startTrip: erro inesperado: $e', stack: stack.toString());
      _error = 'Falha ao iniciar viagem: $e';
      _loading = false;
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      _isStartingTrip = false;
      notifyListeners();
    }
  }

  void _startStream() {
    _sub?.cancel();
    _tracking = true;
    notifyListeners();
    AppLogger.log('TRACKING', 'Iniciando stream de GPS...');

    // SEM distanceFilter — recebe todas as posições do GPS
    _sub = _location.positionStream(
      distanceFilterMeters: 0,
    ).listen(
      (pos) async {
        if (_paused || _activeTrip == null) return;
        AppLogger.log('TRACKING', 'Posição recebida: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)} speed=${(pos.speed * 3.6).toStringAsFixed(1)}km/h acc=${pos.accuracy.toStringAsFixed(0)}m');

        // Sempre atualiza posição atual para o mapa
        _lastLat = pos.latitude;
        _lastLng = pos.longitude;
        _currentSpeed = (pos.speed * 3.6); // m/s -> km/h
        notifyListeners();

        // Grava todos os pontos recebidos
        if (_shouldRecordPoint(pos)) {
          await _sendPoint(pos);
        }
      },
      onError: (e) {
        AppLogger.log('TRACKING', 'Erro no stream de GPS: $e');
        _error = 'Erro de GPS: $e';
        notifyListeners();
      },
    );
  }

  /// Grava todos os pontos recebidos do GPS, sem restrições de distância/speed.
  bool _shouldRecordPoint(Position pos) {
    if (_lastSentLat == null || _lastSentLng == null) {
      AppLogger.log('TRACKING', 'Primeiro ponto — sempre grava');
      return true;
    }

    final meters = _calculateDistance(
      _lastSentLat!, _lastSentLng!, pos.latitude, pos.longitude,
    );
    final speedKmh = pos.speed * 3.6;
    AppLogger.log('TRACKING', 'Distância desde último gravado: ${meters.toStringAsFixed(1)}m, speed: ${speedKmh.toStringAsFixed(1)}km/h');

    return true;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeTrip != null && !_paused) {
        // Calcula duração a partir do start_time para precisão mesmo após background
        if (_tripStartTime != null) {
          _totalDurationSeconds = DateTime.now().difference(_tripStartTime!).inSeconds;
        } else {
          _totalDurationSeconds++;
        }
        notifyListeners();
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _sendPoint(Position pos) async {
    if (_activeTrip == null) return;
    try {
      // Calcula distância desde o último ponto GRAVADO
      double metersMoved = 0;
      if (_lastSentLat != null && _lastSentLng != null) {
        metersMoved = _calculateDistance(
          _lastSentLat!, _lastSentLng!, pos.latitude, pos.longitude,
        );
        _currentDistanceKm += metersMoved / 1000.0;
      }

      // Calcula velocidade: se pos.speed for 0 (comum em muitos Androids),
      // calcula manualmente a partir da distância e tempo entre pontos
      double speedMs = pos.speed;
      if (speedMs <= 0 && _lastPointAt != null && metersMoved > 0) {
        final elapsedSec = DateTime.now().difference(_lastPointAt!).inSeconds;
        if (elapsedSec > 0) {
          speedMs = metersMoved / elapsedSec;
          AppLogger.log('TRACKING', 'Speed calculada manualmente: ${(speedMs * 3.6).toStringAsFixed(1)}km/h (dist=${metersMoved.toStringAsFixed(1)}m em ${elapsedSec}s)');
        }
      }
      _currentSpeed = speedMs * 3.6; // m/s -> km/h

      // Atualiza último ponto gravado
      _lastSentLat = pos.latitude;
      _lastSentLng = pos.longitude;

      if (_currentSpeed >= 2 && _lastPointAt != null) {
        _movingSeconds += DateTime.now().difference(_lastPointAt!).inSeconds;
      }
      _lastPointAt = DateTime.now();
      // Adiciona ponto à rota para traçado em tempo real
      _routePoints.add(LatLng(pos.latitude, pos.longitude));
      notifyListeners();

      AppLogger.log('TRACKING', 'Enviando ponto à API: trip=${_activeTrip!.id} lat=${pos.latitude} lng=${pos.longitude} speed=${_currentSpeed.toStringAsFixed(1)}km/h');
      await _api.addPoint(
        _activeTrip!.id,
        lat: pos.latitude,
        lng: pos.longitude,
        altitude: pos.altitude,
        speed: speedMs, // envia speed em m/s (calculada se device não reportou)
        heading: pos.heading,
        accuracy: pos.accuracy,
        recordedAt: DateTime.now().toIso8601String(),
      );
      AppLogger.log('TRACKING', 'Ponto enviado com sucesso!');
    } on ApiException catch (e) {
      AppLogger.log('TRACKING', 'Erro ao enviar ponto: ${e.message}');
      _error = 'Falha ao enviar ponto: ${e.message}';
      notifyListeners();
    } catch (e) {
      AppLogger.log('TRACKING', 'Erro inesperado: $e');
    }
  }

  /// Pausa a viagem (spec §8).
  Future<void> pause() async {
    AppLogger.log('TRACKING', '=== pause() chamado === activeTrip=${_activeTrip?.id}');
    if (_activeTrip == null) {
      AppLogger.log('TRACKING', 'pause: nenhuma viagem ativa — ignorando');
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      AppLogger.log('TRACKING', 'pause: chamando API pauseTrip...');
      await _api.pauseTrip(_activeTrip!.id);
      AppLogger.log('TRACKING', 'pause: API pausou com sucesso');
      _paused = true;
      _sub?.cancel();
      _sub = null;
      _tracking = false;
      _stopTicker();
      AppLogger.log('TRACKING', 'pause: stream e ticker parados, _paused=$_paused');
    } catch (e, stack) {
      AppLogger.error('TRACKING', 'pause: erro ao pausar: $e', stack: stack.toString());
      _error = 'Falha ao pausar: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Retoma a viagem após pausa (spec §8).
  Future<void> resume() async {
    AppLogger.log('TRACKING', '=== resume() chamado === activeTrip=${_activeTrip?.id}, paused=$_paused');
    if (_activeTrip == null) {
      AppLogger.log('TRACKING', 'resume: nenhuma viagem ativa — ignorando');
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      AppLogger.log('TRACKING', 'resume: chamando API resumeTrip...');
      await _api.resumeTrip(_activeTrip!.id);
      AppLogger.log('TRACKING', 'resume: API retomou com sucesso');
      _paused = false;
      _lastPointAt = DateTime.now();
      AppLogger.log('TRACKING', 'resume: reiniciando stream e ticker...');
      _startStream();
      _startTicker();
      AppLogger.log('TRACKING', 'resume: stream e ticker ativos, _paused=$_paused');
      // Reinicia background service se não estiver rodando
      if (!kIsWeb) {
        try {
          final isBgRunning = await TrackingService.isRunning();
          if (!isBgRunning) {
            AppLogger.log('TRACKING', 'resume: background service parado — reiniciando...');
            await TrackingService.start(
              tripId: _activeTrip!.id,
              token: _api.token ?? '',
              apiBaseUrl: AppConfig.apiBaseUrl,
            );
            AppLogger.log('TRACKING', 'resume: background service reiniciado');
          }
        } catch (e) {
          AppLogger.error('TRACKING', 'resume: erro ao reiniciar background: $e');
        }
      }
    } catch (e, stack) {
      AppLogger.error('TRACKING', 'resume: erro ao retomar: $e', stack: stack.toString());
      _error = 'Falha ao retomar: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Finaliza a viagem (spec §12).
  Future<bool> finish({String? name}) async {
    if (_activeTrip == null) return false;
    _loading = true;
    notifyListeners();
    try {
      await _sub?.cancel();
      _sub = null;
      _tracking = false;
      _stopTicker();
      // Para o serviço de background
      if (!kIsWeb) {
        try {
          await TrackingService.stop();
        } catch (e) {
          AppLogger.error('TRACKING', 'Erro ao parar background service: $e');
        }
      }
      final finished = await _api.finishTrip(_activeTrip!.id, name: name);
      _history.insert(0, finished);
      _activeTrip = null;
      _currentDistanceKm = 0;
      _movingSeconds = 0;
      _totalDurationSeconds = 0;
      _currentSpeed = 0;
      _lastSentLat = null;
      _lastSentLng = null;
      _routePoints.clear();
      notifyListeners();
      // Envia logs ao servidor automaticamente após finalizar viagem
      AppLogger.instance.uploadToServer();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Cancela tudo (sem finalizar no servidor) — usado em logout.
  Future<void> cancelLocal() async {
    await _sub?.cancel();
    _sub = null;
    _tracking = false;
    _paused = false;
    _activeTrip = null;
    if (!kIsWeb) {
      try {
        await TrackingService.stop();
      } catch (e) {
        debugPrint('Erro ao parar background service: $e');
      }
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Apaga uma viagem do histórico (spec §13: gerenciar viagens).
  /// Não permite apagar viagem ativa/pausada.
  Future<bool> deleteTrip(int tripId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.deleteTrip(tripId);
      _history.removeWhere((t) => t.id == tripId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Falha ao apagar viagem: $e';
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Cálculo de distância entre dois pontos (fórmula de Haversine).
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // metros
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double deg) => deg * (3.14159265359 / 180);
  double sin(double x) => _math.sin(x);
  double cos(double x) => _math.cos(x);
  double atan2(double y, double x) => _math.atan2(y, x);
  double sqrt(double x) => _math.sqrt(x);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }
}

// Extensão simples para firstWhereOrNull (evita depender de collection).
extension _IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
