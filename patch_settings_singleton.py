import re

with open('lib/providers/settings_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Make it a singleton
singleton_code = """
class SettingsProvider extends ChangeNotifier {
  static final SettingsProvider _instance = SettingsProvider._internal();
  static SettingsProvider get instance => _instance;
  SettingsProvider._internal();
"""
content = re.sub(r'class SettingsProvider extends ChangeNotifier \{', singleton_code, content)

# Remove the default constructor usage in main.dart
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    main_content = f.read()
main_content = main_content.replace('final settingsProvider = SettingsProvider();', 'final settingsProvider = SettingsProvider.instance;')

with open('lib/providers/settings_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(main_content)
