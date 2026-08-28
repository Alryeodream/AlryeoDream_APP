import re

with open('lib/providers/settings_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add imports
imports = """import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
"""
content = content.replace("import 'package:flutter/material.dart';\nimport 'package:shared_preferences/shared_preferences.dart';", imports)

# Update setThemeMode and setTextScale
setters = """
  Future<void> _syncToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'themeModeIndex': _themeMode.index,
          'textScale': _textScale,
        });
      } catch (e) {
        // 무시
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
"""
content = re.sub(r'  Future<void> setThemeMode\(ThemeMode mode\).*?notifyListeners\(\);\n  \}', setters, content, flags=re.DOTALL)

with open('lib/providers/settings_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)
