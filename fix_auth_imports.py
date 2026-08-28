import re

with open('lib/screens/auth/login_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace("import '../../social_login_button.dart';", "import '../../widgets/social_login_button.dart';")
with open('lib/screens/auth/login_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

with open('lib/screens/auth/signup_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace("import '../../age_picker_sheet.dart';", "import '../../widgets/age_picker_sheet.dart';")
with open('lib/screens/auth/signup_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

