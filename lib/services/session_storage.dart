import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

/// Persistência simples da sessão (token + user) em SharedPreferences.
///
/// Permite "manter logado" — o usuário não precisa digitar credenciais
/// toda vez que abre o app.
class SessionStorage {
  static const _keySession = 'motohead_session';
  static const _keyRemember = 'motohead_remember_login';

  /// Salva a sessão para restauração automática no próximo boot.
  static Future<void> saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySession, session.encode());
    await prefs.setBool(_keyRemember, true);
  }

  /// Marca "não lembrar" — limpa a sessão persistida.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySession);
    await prefs.setBool(_keyRemember, false);
  }

  /// Recupera a sessão persistida (ou null se não houver).
  static Future<AuthSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_keyRemember) ?? false;
    if (!remember) return null;
    final raw = prefs.getString(_keySession);
    return AuthSession.decode(raw);
  }

  /// True se o usuário marcou "manter logado".
  static Future<bool> isRememberLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRemember) ?? false;
  }
}
