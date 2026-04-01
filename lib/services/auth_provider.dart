import 'package:flutter/material.dart';
import 'package:river_watch/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool isLoading = false;

  // ✅ REPLACE the entire login method with this:
  Future<void> login(String userName, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      await _api.login(userName, password); // throws if credentials are wrong
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
