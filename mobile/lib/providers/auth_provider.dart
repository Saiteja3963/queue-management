import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this.api);

  final ApiService api;
  User? user;
  bool loading = true;
  String? error;

  static const _tokenKey = 'qf_token';

  Future<void> bootstrap() async {
    loading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token != null) {
        api.setToken(token);
        user = await api.me();
      }
    } catch (_) {
      await logout();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    error = null;
    notifyListeners();
    try {
      final token = await api.login(email: email, password: password);
      api.setToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      user = await api.me();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String fullName,
    required String password,
  }) async {
    await api.register(email: email, fullName: fullName, password: password);
    await login(email, password);
  }

  Future<void> logout() async {
    user = null;
    api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    notifyListeners();
  }
}
