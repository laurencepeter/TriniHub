import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_storage_listener.dart';

class ThemeSettings {
  ThemeSettings._();

  static const _themePreferenceKey = 'theme_mode_is_dark';
  static const _reduceMotionKey = 'reduce_motion_enabled';
  static final ThemeSettings instance = ThemeSettings._();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);
  final ValueNotifier<bool> reduceMotion = ValueNotifier(false);
  bool _storageListenerInitialized = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    reduceMotion.value = prefs.getBool(_reduceMotionKey) ?? false;
    final isDark = prefs.getBool(_themePreferenceKey);
    if (isDark == null) {
      _ensureStorageListener();
      return;
    }
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    _ensureStorageListener();
  }

  void setThemeMode(bool isDark) {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool(_themePreferenceKey, isDark),
    );
  }

  void setReduceMotion(bool enabled) {
    reduceMotion.value = enabled;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool(_reduceMotionKey, enabled),
    );
  }

  void _ensureStorageListener() {
    if (_storageListenerInitialized) {
      return;
    }
    _storageListenerInitialized = true;
    registerStorageListener(_themePreferenceKey, (value) {
      if (value == null) {
        return;
      }
      final isDark = value == 'true';
      final nextMode = isDark ? ThemeMode.dark : ThemeMode.light;
      if (themeMode.value != nextMode) {
        themeMode.value = nextMode;
      }
    });
  }
}
