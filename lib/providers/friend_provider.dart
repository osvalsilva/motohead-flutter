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
      // Nota: Precisa adicionar método público no ApiService ou usar método privado
      // Por enquanto, vamos deixar vazio até adicionar o método correto
      _friends = [];
      _error = 'Funcionalidade em desenvolvimento';
    } catch (e) {
      _error = 'Erro ao carregar amigos: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}