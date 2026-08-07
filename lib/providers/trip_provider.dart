import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/trip.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

/// Estado da viagem ativa + tracking GPS (spec §5, §6, §8).
///
/// No MVP:
/// - start: cria a trip no servidor e começa a escutar GPS.
/// - pause/resume: pausa o stream localmente (sem endpoint ainda — gap do backend).
/// - finish: para o stream e finaliza no servidor.
/// - pontos são enviados um-a-um via /api/tracking/trips/{id}/point.
class TripProvider extends ChangeNotifier {
  final _api = ApiService.instance;
  final _location = LocationService.instance;

  bool _loading = false;
  bool _tracking = false;
  bool _paused = false;
  Trip? _activeTrip;
  List<Trip> _history = [];
  String? _error;

  // Estatísticas locais (espelhando o backend).
  double _currentDistanceKm = 0;
  int _movingSeconds = 0;
  double _currentSpeed = 0;
  double? _lastLat;
  double? _lastLng;
  DateTime? _lastPointAt;
  StreamSubscription<Position>? _sub;

  bool get loading => _loading;
  bool get tracking => _tracking;
  bool get paused => _paused;
  bool get hasActiveTrip => _activeTrip != null && _activeTrip!.isActive;
  Trip? get activeTrip => _activeTrip;
  List<Trip> get history => _history;
  String? get error => _error;

  double get currentDistanceKm => _currentDistanceKm;
  int get movingSeconds => _movingSeconds;
  double get currentSpeed => _currentSpeed;

  /// Carrega histórico de viagens do usuário.
  Future<void> loadHistory() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _history = await _api.listTrips();
      // Detecta viagem ativa no servidor.
      final active = _history.firstWhereOrNull((t) => t.isActive);
      if (active != null && _activeTrip == null) {
        _activeTrip = active;
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
        _error = 'Permissão de localização negada';
        notifyListeners();
        return false;
      }

      final pos = await _location.currentPosition();
      final trip = await _api.startTrip(
        name: name,
        motorcycleId: motorcycleId,
        startLat: pos.latitude,
        startLng: pos.longitude,
      );
      _activeTrip = trip;
      _currentDistanceKm = 0;
      _movingSeconds = 0;
      _currentSpeed = 0;
      _lastLat = pos.latitude;
      _lastLng = pos.longitude;
      _lastPointAt = DateTime.now();
      _paused = false;
      notifyListeners();

      // Envia o primeiro ponto.
      await _sendPoint(pos);

      // Começa o stream de tracking.
      _startStream();
      return true;
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

  Future<void> _sendPoint(Position pos) async {
    if (_activeTrip == null) return;
    try {
      // Atualiza estatísticas locais.
      if (_lastLat != null && _lastLng != null) {
        final meters = Geolocator.distanceBetween(
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
    } catch (e) {
      _error = 'Falha ao retomar: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Finaliza a viagem (spec §12).
  Future<bool> finish() async {
    if (_activeTrip == null) return false;
    _loading = true;
    notifyListeners();
    try {
      await _sub?.cancel();
      _sub = null;
      _tracking = false;
      final finished = await _api.finishTrip(_activeTrip!.id);
      _history.insert(0, finished);
      _activeTrip = null;
      _currentDistanceKm = 0;
      _movingSeconds = 0;
      _currentSpeed = 0;
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
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
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
