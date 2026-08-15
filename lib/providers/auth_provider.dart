import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/session_storage.dart';

/// Estado de autenticação do app.
///
/// Suporta "manter logado" — a sessão é persistida em SharedPreferences
/// e restaurada automaticamente no boot do app.
class AuthProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  bool _loading = true; // Começa true para mostrar splash enquanto restaura sessão
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
  Future<void> restore() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await SessionStorage.loadSession();
      if (saved != null && saved.token.isNotEmpty) {
        _session = saved;
        _api.token = saved.token;
      }
    } catch (e) {
      // Sessão inválida — ignora silenciosamente
      _session = null;
    }
    _loading = false;
    notifyListeners();
  }

  /// Login com email/senha.
  /// Se [remember] for true, a sessão é persistida para auto-login.
  Future<bool> login(String email, String password, {bool remember = true}) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final session = await _api.login(email, password);
      _session = session;
      if (remember) {
        await SessionStorage.saveSession(session);
      }
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

  /// Logout — limpa sessão local e persistida.
  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    _session = null;
    _api.token = null;
    await SessionStorage.clearSession();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
