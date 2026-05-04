import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _keyHandedness = 'handedness';
  static const _keyTheme = 'theme_mode';
  static const _keyNotifPermAsked = 'notif_perm_asked';
  static const _keyUseThousandSep = 'use_thousand_sep';
  static const _keySmartDecimals = 'smart_decimals';
  static const _keyWelcomeSeen = 'welcome_seen';
  static const _keyAssistedMode = 'assisted_mode';

  bool _useThousandSep = true;
  bool _smartDecimals = true;

  bool get useThousandSep => _useThousandSep;
  bool get smartDecimals => _smartDecimals;

  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    _useThousandSep = sp.getBool(_keyUseThousandSep) ?? true;
    _smartDecimals = sp.getBool(_keySmartDecimals) ?? true;
  }

  Future<void> setUseThousandSep(bool value) async {
    _useThousandSep = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_keyUseThousandSep, value);
  }

  Future<void> setSmartDecimals(bool value) async {
    _smartDecimals = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_keySmartDecimals, value);
  }

  Future<bool> hasSeenWelcome() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_keyWelcomeSeen) ?? false;
  }

  Future<void> markWelcomeSeen() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_keyWelcomeSeen, true);
  }

  Future<bool> assistedMode() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_keyAssistedMode) ?? true;
  }

  Future<void> setAssistedMode(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_keyAssistedMode, value);
  }

  Future<String> getHandedness() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyHandedness) ?? 'right';
  }

  Future<void> setHandedness(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHandedness, value);
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString(_keyTheme)) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.dark:
        await prefs.setString(_keyTheme, 'dark');
        break;
      case ThemeMode.light:
        await prefs.setString(_keyTheme, 'light');
        break;
      default:
        await prefs.setString(_keyTheme, 'system');
        break;
    }
  }

  Future<bool> hasAskedNotifPerm() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_keyNotifPermAsked) ?? false;
  }

  Future<void> markNotifPermAsked() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_keyNotifPermAsked, true);
  }
}
