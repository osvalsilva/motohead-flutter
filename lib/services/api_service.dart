import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/user.dart';
import '../models/trip.dart';
import '../models/event.dart';
import '../models/motorcycle.dart';

/// Exceção de API com status code + mensagem + corpo (para debug).
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;
  final String? rawBody;

  ApiException(this.statusCode, this.message, {this.errors, this.rawBody});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Cliente HTTP da API MotoHead.
///
/// Encapsula JWT, base URL e parsing. Todos os métodos lançam [ApiException]
/// em caso de erro não-2xx.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  String? _token;

  /// Define o token JWT obtido em /api/auth/login.
  set token(String? value) => _token = value;

  String? get token => _token;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// Headers padrão (JSON + Authorization se houver token).
  Map<String, String> get _headers {
    final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Uri _uri(String path) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$cleanPath');
  }

  /// Decodifica a resposta JSON e valida o envelope { success, message, data }.
  /// Retorna o `data` interno.
  dynamic _decode(http.Response resp) {
    final body = resp.body.isEmpty ? '{}' : resp.body;
    Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(resp.statusCode, 'Resposta inválida (não-JSON)', rawBody: body);
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(
        resp.statusCode,
        json['message'] as String? ?? 'Erro ${resp.statusCode}',
        errors: json['errors'] as Map<String, dynamic>?,
        rawBody: body,
      );
    }

    // Envelope padrão: { success, message, data }
    if (json.containsKey('data')) return json['data'];
    return json;
  }

  Future<dynamic> _get(String path, {Map<String, String>? query}) async {
    final uri = _uri(path).replace(queryParameters: query);
    print('ApiService._get: URL = $uri');
    print('ApiService._get: Headers = $_headers');
    final resp = await http.get(uri, headers: _headers).timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw ApiException(0, 'Tempo limite excedido'),
    );
    print('ApiService._get: Status = ${resp.statusCode}');
    print('ApiService._get: Body = ${resp.body}');
    return _decode(resp);
  }

  Future<dynamic> _post(String path, {Map<String, dynamic>? body}) async {
    final resp = await http
        .post(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
        .timeout(const Duration(seconds: 20));
    return _decode(resp);
  }

  Future<dynamic> _put(String path, {Map<String, dynamic>? body}) async {
    final resp = await http
        .put(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
        .timeout(const Duration(seconds: 20));
    return _decode(resp);
  }

  // ----------------------- AUTH -----------------------

  /// POST /api/auth/login
  Future<AuthSession> login(String email, String password) async {
    final data = await _post('/api/auth/login', body: {
      'email': email,
      'password': password,
    });
    _token = data['token'] as String?;
    return AuthSession.fromJson(data as Map<String, dynamic>);
  }

  /// GET /api/auth/me
  Future<User> me() async {
    final data = await _get('/api/auth/me');
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// POST /api/auth/logout (stateless — só limpa o token local)
  Future<void> logout() async {
    try {
      await _post('/api/auth/logout');
    } finally {
      _token = null;
    }
  }

  // ----------------------- TRIPS / TRACKING -----------------------

  /// GET /api/tracking/trips — lista viagens do usuário.
  Future<List<Trip>> listTrips({String? status, int page = 1}) async {
    final query = <String, String>{'page': page.toString()};
    if (status != null && status.isNotEmpty) query['status'] = status;
    final data = await _get('/api/tracking/trips', query: query);
    final list = data['trips'] as List? ?? [];
    return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/tracking/trips/start
  Future<Trip> startTrip({
    required String name,
    int? motorcycleId,
    String? startLocation,
    double? startLat,
    double? startLng,
  }) async {
    final data = await _post('/api/tracking/trips/start', body: {
      'name': name,
      if (motorcycleId != null) 'motorcycle_id': motorcycleId,
      if (startLocation != null) 'start_location': startLocation,
      if (startLat != null) 'start_lat': startLat,
      if (startLng != null) 'start_lng': startLng,
    });
    return Trip.fromJson(data['trip'] as Map<String, dynamic>);
  }

  /// POST /api/tracking/trips/{id}/point
  Future<void> addPoint(
    int tripId, {
    required double lat,
    required double lng,
    double? altitude,
    double? speed,
    double? heading,
    double? accuracy,
    int? batteryLevel,
    String? recordedAt,
  }) async {
    await _post('/api/tracking/trips/$tripId/point', body: {
      'lat': lat,
      'lng': lng,
      if (altitude != null) 'altitude': altitude,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      if (accuracy != null) 'accuracy': accuracy,
      if (batteryLevel != null) 'battery_level': batteryLevel,
      if (recordedAt != null) 'recorded_at': recordedAt,
    });
  }

  /// POST /api/tracking/trips/{id}/finish
  Future<Trip> finishTrip(int tripId) async {
    final data = await _post('/api/tracking/trips/$tripId/finish');
    return Trip.fromJson(data['trip'] as Map<String, dynamic>);
  }

  /// POST /api/tracking/trips/{id}/pause
  Future<Trip> pauseTrip(int tripId) async {
    final data = await _post('/api/tracking/trips/$tripId/pause');
    return Trip.fromJson(data['trip'] as Map<String, dynamic>);
  }

  /// POST /api/tracking/trips/{id}/resume
  Future<Trip> resumeTrip(int tripId) async {
    final data = await _post('/api/tracking/trips/$tripId/resume');
    return Trip.fromJson(data['trip'] as Map<String, dynamic>);
  }

  // ----------------------- SOS -----------------------

  /// POST /api/sos/trigger — Aciona o SOS
  Future<Map<String, dynamic>> triggerSos({
    required double lat,
    required double lng,
    double? accuracy,
    int? tripId,
  }) async {
    return await _post('/api/sos/trigger', body: {
      'latitude': lat,
      'longitude': lng,
      if (accuracy != null) 'accuracy': accuracy,
      if (tripId != null) 'trip_id': tripId,
    }) as Map<String, dynamic>;
  }

  /// POST /api/sos/{id}/location — Atualiza localização durante SOS
  Future<void> updateSosLocation(
    int sosId, {
    required double lat,
    required double lng,
    double? accuracy,
    double? speed,
    int? batteryLevel,
  }) async {
    await _post('/api/sos/$sosId/location', body: {
      'latitude': lat,
      'longitude': lng,
      if (accuracy != null) 'accuracy': accuracy,
      if (speed != null) 'speed': speed,
      if (batteryLevel != null) 'battery_level': batteryLevel,
    });
  }

  /// POST /api/sos/{id}/resolve — Encerra o SOS
  Future<void> resolveSos(int sosId) async {
    await _post('/api/sos/$sosId/resolve');
  }

  // ----------------------- EVENTS -----------------------

  /// GET /api/events
  Future<List<MotoEvent>> listEvents({String? status, int page = 1}) async {
    final query = <String, String>{'page': page.toString()};
    if (status != null && status.isNotEmpty) query['status'] = status;
    final data = await _get('/api/events', query: query);
    final list = data['events'] as List? ?? [];
    return list.map((e) => MotoEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ----------------------- FRIENDS -----------------------

  /// GET /api/friends — lista amigos do usuário
  Future<List<dynamic>> listFriends() async {
    final data = await _get('/api/friends');
    return data as List<dynamic>;
  }

  /// POST /api/friends/sos — envia SOS para amigos
  Future<Map<String, dynamic>> sendSos({
    double? lat,
    double? lng,
    String? message,
  }) async {
    return await _post('/api/friends/sos', body: {
      'latitude': lat ?? 0.0,
      'longitude': lng ?? 0.0,
      'message' => message ?? 'SOS acionado',
    }) as Map<String, dynamic>;
  }

  // ----------------------- MOTORCYCLES -----------------------

  /// GET /api/motorcycles
  Future<List<Motorcycle>> listMotorcycles() async {
    final data = await _get('/api/motorcycles');
    final list = (data is List)
        ? data
        : (data['motorcycles'] as List? ?? []);
    return list.map((e) => Motorcycle.fromJson(e as Map<String, dynamic>)).toList();
  }
}
