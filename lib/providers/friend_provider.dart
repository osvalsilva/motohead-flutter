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
      final data = await _apiService.listFriends();
      _friends = data.map((json) => Friend.fromJson(json)).toList();
    } catch (e) {
      _error = 'Erro ao carregar amigos: $e';
      _friends = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}