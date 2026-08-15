import 'dart:async';
import 'dart:math' as _math;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/trip.dart';
import '../services/api_service.dart';
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
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _activeTrip != null && !_paused) {
      // App voltou do background — recalcula tempo a partir do start_time
      if (_tripStartTime != null) {
        _totalDurationSeconds = DateTime.now().difference(_tripStartTime!).inSeconds;
      }
      // Reinicia o ticker se foi parado pelo sistema
      if (_ticker == null || !_ticker!.isActive) {
        _startTicker();
      }
      // Reinicia o stream de GPS se necessário
      if (_sub == null) {
        _startStream();
      }
      notifyListeners();
    }
  }

  bool _loading = false;
  bool _tracking = false;
  bool _paused = false;
  Trip? _activeTrip;
  List<Trip> _history = [];
  String? _error;

  // Estatísticas locais (espelhando o backend).
  double _currentDistanceKm = 0;
  int _movingSeconds = 0;
  int _totalDurationSeconds = 0; // Duração total da viagem (incluindo paradas)
  double _currentSpeed = 0;
  double? _lastLat;
  double? _lastLng;
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
        // Calcula tempo total a partir do start_time do servidor
        if (active.startTime != null) {
          try {
            final start = DateTime.parse(active.startTime!);
            _tripStartTime = start;
            // Atualiza duração com tempo real decorrido
            final elapsed = DateTime.now().difference(start).inSeconds;
            if (elapsed > _totalDurationSeconds) {
              _totalDurationSeconds = elapsed;
            }
          } catch (_) {}
        }
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
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final ok = await _location.ensurePermission();
      if (!ok) {
        _error = 'Permissão de localização negada. Ative o GPS nas configurações do dispositivo.';
        notifyListeners();
        return false;
      }

      final pos = await _location.currentPosition();

      // Validação extra: não inicia viagem com coordenadas inválidas
      if (pos.latitude == 0.0 && pos.longitude == 0.0) {
        _error = 'GPS retornou coordenadas inválidas. Verifique se o GPS está ativado.';
        notifyListeners();
        return false;
      }

      final trip = await _api.startTrip(
        name: name,
        motorcycleId: motorcycleId,
        startLat: pos.latitude,
        startLng: pos.longitude,
      );
      _activeTrip = trip;
      _currentDistanceKm = 0;
      _movingSeconds = 0;
      _totalDurationSeconds = 0;
      _currentSpeed = 0;
      _lastLat = pos.latitude;
      _lastLng = pos.longitude;
      _lastPointAt = DateTime.now();
      // Usa o start_time do servidor se disponível, senão usa agora
      if (trip.startTime != null) {
        try {
          _tripStartTime = DateTime.parse(trip.startTime!);
        } catch (_) {
          _tripStartTime = DateTime.now();
        }
      } else {
        _tripStartTime = DateTime.now();
      }
      _paused = false;
      _routePoints.clear();
      _routePoints.add(LatLng(pos.latitude, pos.longitude));
      notifyListeners();

      // Envia o primeiro ponto.
      await _sendPoint(pos);

      // Começa o stream de tracking.
      _startStream();
      // Começa o ticker de duração.
      _startTicker();
      // Inicia o serviço de background (continua tracking ao fechar o app)
      if (!kIsWeb) {
        await TrackingService.start(
          tripId: trip.id,
          token: _api.token ?? '',
          apiBaseUrl: AppConfig.apiBaseUrl,
        );
      }
      return true;
    } on UnimplementedError catch (e) {
      _error = 'Geolocator temporariamente desabilitado. Verifique se o GPS está ativado nas configurações do navegador.';
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Falha ao iniciar viagem: $e';
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _startStream() {
    _sub?.cancel();
    _tracking = true;
    notifyListeners();
    
    _sub = _location.positionStream().listen(
      (pos) async {
        if (_paused || _activeTrip == null) return;
        await _sendPoint(pos);
      },
      onError: (e) {
        _error = 'Erro de GPS: $e';
        notifyListeners();
      },
    );
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
    // Rejeita coordenadas inválidas (0,0 = meio do oceano)
    if (pos.latitude == 0.0 && pos.longitude == 0.0) return;
    try {
      // Atualiza estatísticas locais.
      if (_lastLat != null && _lastLng != null) {
        final meters = _calculateDistance(
          _lastLat!, _lastLng!, pos.latitude, pos.longitude,
        );
        if (meters > 5) {
          _currentDistanceKm += meters / 1000.0;
        }
      }
      _currentSpeed = (pos.speed * 3.6); // m/s -> km/h
      if (_currentSpeed >= 2 && _lastPointAt != null) {
        _movingSeconds += DateTime.now().difference(_lastPointAt!).inSeconds;
      }
      _lastLat = pos.latitude;
      _lastLng = pos.longitude;
      _lastPointAt = DateTime.now();
      // Adiciona ponto à rota para traçado em tempo real
      _routePoints.add(LatLng(pos.latitude, pos.longitude));
      notifyListeners();

      await _api.addPoint(
        _activeTrip!.id,
        lat: pos.latitude,
        lng: pos.longitude,
        altitude: pos.altitude,
        speed: pos.speed,
        heading: pos.heading,
        accuracy: pos.accuracy,
        recordedAt: DateTime.now().toIso8601String(),
      );
    } on ApiException catch (e) {
      // Não aborta a viagem por erro de rede (spec §27: tracking continua offline).
      _error = 'Falha ao enviar ponto: ${e.message}';
      notifyListeners();
    }
  }

  /// Pausa a viagem (spec §8).
  Future<void> pause() async {
    if (_activeTrip == null) return;
    _loading = true;
    notifyListeners();
    try {
      await _api.pauseTrip(_activeTrip!.id);
      _paused = true;
      _sub?.cancel();
      _sub = null;
      _tracking = false;
      _stopTicker();
    } catch (e) {
      _error = 'Falha ao pausar: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Retoma a viagem após pausa (spec §8).
  Future<void> resume() async {
    if (_activeTrip == null) return;
    _loading = true;
    notifyListeners();
    try {
      await _api.resumeTrip(_activeTrip!.id);
      _paused = false;
      _lastPointAt = DateTime.now();
      _startStream();
      _startTicker();
    } catch (e) {
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
        await TrackingService.stop();
      }
      final finished = await _api.finishTrip(_activeTrip!.id, name: name);
      _history.insert(0, finished);
      _activeTrip = null;
      _currentDistanceKm = 0;
      _movingSeconds = 0;
      _totalDurationSeconds = 0;
      _currentSpeed = 0;
      _routePoints.clear();
      notifyListeners();
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
      await TrackingService.stop();
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
