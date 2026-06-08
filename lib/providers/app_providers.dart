import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Theme Provider ───────────────────────────────────────────────────────────
// On first launch: reads system setting
// After user changes: persists to SharedPreferences
class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;
  bool get isLight => _mode == ThemeMode.light;
  bool get isSystem => _mode == ThemeMode.system;

  /// Call once at app start — loads saved preference or falls back to system
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == null) {
      _mode = ThemeMode.system; // first launch → respect device setting
    } else {
      _mode = _fromString(saved);
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _toString(mode));
  }

  void toggleDarkLight(BuildContext context) {
    // If currently system, check what system actually is and flip it
    final brightness = MediaQuery.platformBrightnessOf(context);
    if (_mode == ThemeMode.system) {
      // System is dark → switch to light; system is light → switch to dark
      setMode(brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
    } else {
      setMode(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
    }
  }

  /// Returns true if the effective theme is dark (considering system mode)
  bool effectiveIsDark(BuildContext context) {
    if (_mode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _mode == ThemeMode.dark;
  }

  static ThemeMode _fromString(String s) {
    switch (s) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      default:
        return 'system';
    }
  }
}

// ─── Locale Provider ──────────────────────────────────────────────────────────
// On first launch: uses device locale if supported, otherwise English
class LocaleProvider extends ChangeNotifier {
  static const _key = 'locale';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  bool get isSwahili => _locale.languageCode == 'sw';
  bool get isEnglish => _locale.languageCode == 'en';

  /// Call once at app start
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);

    if (saved != null) {
      _locale = Locale(saved);
    } else {
      // First launch — check device locale
      final deviceLang =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      _locale = deviceLang == 'sw' ? const Locale('sw') : const Locale('en');
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  Future<void> setEnglish() => setLocale(const Locale('en'));
  Future<void> setSwahili() => setLocale(const Locale('sw'));
}
