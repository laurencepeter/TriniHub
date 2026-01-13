import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeSettings {
  ThemeSettings._();

  static const _themePreferenceKey = 'theme_mode_is_dark';
  static final ThemeSettings instance = ThemeSettings._();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themePreferenceKey);
    if (isDark == null) {
      return;
    }
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void setThemeMode(bool isDark) {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool(_themePreferenceKey, isDark),
    );
  }
}
