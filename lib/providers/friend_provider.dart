import 'package:flutter/foundation.dart';
import '../models/friend.dart';
import '../services/api_service.dart';

class FriendProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<Friend> _friends = [];
  bool _loading = false;
  String? _error;

  List<Friend> get friends => _friends;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadFriends() async {
    _loading = true;
    _error = null;
    notifyListeners();

    print('FriendProvider: Iniciando loadFriends');
    print('FriendProvider: isAuthenticated = ${_apiService.isAuthenticated}');
    print('FriendProvider: token existe = ${_apiService.token != null}');
    print('FriendProvider: token tamanho = ${_apiService.token?.length ?? 0}');
    final tokenLength = _apiService.token?.length ?? 0;
    final previewLength = tokenLength > 20 ? 20 : tokenLength;
    print('FriendProvider: token início = ${_apiService.token?.substring(0, previewLength)}');

    try {
      if (!_apiService.isAuthenticated) {
        _error = 'Você precisa estar logado para ver seus amigos';
        _friends = [];
        print('FriendProvider: Usuário não autenticado');
      } else {
        final data = await _apiService.listFriends();
        _friends = data.map((json) => Friend.fromJson(json)).toList();
        print('FriendProvider: Carregados ${_friends.length} amigos');
      }
    } catch (e) {
      // Se a API não estiver disponível ou houver erro de autenticação
      print('FriendProvider: Erro ao carregar amigos: $e');
      _error = 'Adicione amigos pelo site MotoHead para usá-los como contatos de SOS';
      _friends = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}