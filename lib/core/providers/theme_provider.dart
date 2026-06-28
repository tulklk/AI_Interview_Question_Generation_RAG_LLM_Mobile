import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'hiregena-theme';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) { _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_kThemeKey) ?? 'system';
    state = _parse(v);
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kThemeKey, _serialize(mode));
  }

  void toggle() {
    switch (state) {
      case ThemeMode.light:  setTheme(ThemeMode.dark);   break;
      case ThemeMode.dark:   setTheme(ThemeMode.system); break;
      case ThemeMode.system: setTheme(ThemeMode.light);  break;
    }
  }

  static ThemeMode _parse(String v) {
    switch (v) {
      case 'light':  return ThemeMode.light;
      case 'dark':   return ThemeMode.dark;
      default:       return ThemeMode.system;
    }
  }

  static String _serialize(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:  return 'light';
      case ThemeMode.dark:   return 'dark';
      case ThemeMode.system: return 'system';
    }
  }
}

final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((_) => ThemeNotifier());
