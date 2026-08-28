import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 화면 테마(시스템/라이트/다크) 및 전역 글자 크기 배율을 관리하는 Provider.
/// MaterialApp의 themeMode와 MediaQuery의 textScaler를 여기서 나온 값으로
/// 구독시켜서 앱 전체에 실시간으로 반영되도록 한다.
class SettingsProvider extends ChangeNotifier {
  static final SettingsProvider _instance = SettingsProvider._internal();
  static SettingsProvider get instance => _instance;
  SettingsProvider._internal();
  static const String _themeModeKey = 'settings_theme_mode';
  static const String _textScaleKey = 'settings_text_scale';

  static const double minTextScale = 1.0;
  static const double maxTextScale = 1.5;

  ThemeMode _themeMode = ThemeMode.system;
  double _textScale = 1.0;

  ThemeMode get themeMode => _themeMode;
  double get textScale => _textScale;

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final savedThemeIndex = _prefs.getInt(_themeModeKey);
    if (savedThemeIndex != null &&
        savedThemeIndex >= 0 &&
        savedThemeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[savedThemeIndex];
    }

    _textScale = _prefs.getDouble(_textScaleKey) ?? 1.0;
    notifyListeners();
  }

  Future<void> _syncToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'themeModeIndex': _themeMode.index,
          'textScale': _textScale,
        });
      } catch (e) {
        // Ignore
      }
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt(_themeModeKey, mode.index);
    notifyListeners();
    await _syncToCloud();
  }

  Future<void> setTextScale(double scale) async {
    final clamped = scale.clamp(minTextScale, maxTextScale);
    _textScale = clamped;
    await _prefs.setDouble(_textScaleKey, clamped);
    notifyListeners();
    await _syncToCloud();
  }
}