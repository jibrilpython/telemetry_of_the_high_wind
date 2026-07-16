import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserNotifier extends ChangeNotifier {
  UserNotifier() {
    loadUser();
  }
  bool firstTimeUser = true;

  static const String _storageKey = 'sqw_user';

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    firstTimeUser = prefs.getBool(_storageKey) ?? true;
    notifyListeners();
  }

  Future<void> _saveUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, firstTimeUser);
    notifyListeners();
  }

  void setFirstTimeUser(bool value) {
    firstTimeUser = value;
    _saveUser();
    notifyListeners();
  }
}

final userProvider =
    ChangeNotifierProvider<UserNotifier>((ref) => UserNotifier());
