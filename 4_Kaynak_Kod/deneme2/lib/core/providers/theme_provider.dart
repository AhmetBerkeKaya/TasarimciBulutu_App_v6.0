// lib/core/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  // Kayıtlı temayı yükleyen fonksiyon
  void _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  // Temayı değiştiren ve hafızaya kaydeden fonksiyon
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;

    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_themeModeKey, mode.index);
  }
}