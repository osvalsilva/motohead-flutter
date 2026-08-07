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

    try {
      if (!_apiService.isAuthenticated) {
        _error = 'Você precisa estar logado para ver seus amigos';
        _friends = [];
      } else {
        final data = await _apiService.listFriends();
        _friends = data.map((json) => Friend.fromJson(json)).toList();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _error = 'Sessão expirada. Faça login novamente.';
      } else {
        _error = 'Adicione amigos pelo site MotoHead para usá-los como contatos de SOS';
      }
      _friends = [];
    } catch (e) {
      _error = 'Adicione amigos pelo site MotoHead para usá-los como contatos de SOS';
      _friends = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}