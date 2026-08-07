import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_service.dart';

/// Estado de autenticação do app.
///
/// MVP: sessão em memória (não persistida) — usuário loga toda vez que abre.
class AuthProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  bool _loading = false;
  bool _busy = false;
  AuthSession? _session;
  String? _error;

  bool get loading => _loading;
  bool get busy => _busy;
  bool get isAuthenticated => _session != null;
  User? get user => _session?.user;
  String? get error => _error;
  String? get token => _session?.token;

  /// Restaura sessão persistida (chamado no boot do app).
  /// MVP: não faz nada — sessão não persistida.
  Future<void> restore() async {
    _loading = true;
    _error = null;
    notifyListeners();
    // MVP: sem persistência
    _loading = false;
    notifyListeners();
  }

  /// Login com email/senha.
  Future<bool> login(String email, String password) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final session = await _api.login(email, password);
      _session = session;
      // MVP: sem persistência
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Falha de conexão: $e';
      notifyListeners();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Logout — limpa sessão local e notifica.
  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    _session = null;
    _api.token = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
