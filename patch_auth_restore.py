import re

with open('lib/providers/auth_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add imports for StorageService and SettingsProvider
imports = """import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/storage_service.dart';
import 'settings_provider.dart';
import 'package:flutter/material.dart';
"""
content = content.replace("import 'package:cloud_firestore/cloud_firestore.dart';", imports)

# Update _handleFirebaseUser to restore wishlist and settings
restore_logic = """
    _user!.profileCompleted = profileCompleted;
    
    // 로컬 앱 상태(StorageService, SettingsProvider)에 복원(Restore)
    StorageService.instance.wishlistNotifier.value = wishlist.toSet();
    // ThemeModeIndex: 0=system, 1=light, 2=dark
    if (themeModeIndex >= 0 && themeModeIndex <= 2) {
      SettingsProvider.instance.setThemeMode(ThemeMode.values[themeModeIndex]);
    }
    SettingsProvider.instance.setTextScale(textScale);
"""
content = re.sub(r'    _user!\.profileCompleted = profileCompleted;', restore_logic, content)

with open('lib/providers/auth_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)
