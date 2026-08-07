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
      final response = await _apiService.request('GET', '/api/friends');

      if (response['success'] == true && response['data'] != null) {
        _friends = (response['data'] as List)
            .map((json) => Friend.fromJson(json))
            .toList();
      } else {
        _error = response['message'] ?? 'Erro ao carregar amigos';
      }
    } catch (e) {
      _error = 'Erro ao carregar amigos: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}