import re

# Fix home_screen.dart
with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import '../custom_date_range_picker_dialog.dart';", "import '../widgets/custom_date_range_picker_dialog.dart';")
content = content.replace("import '../benefit_card.dart';", "import '../widgets/benefit_card.dart';")
content = content.replace("import 'home/", "import '../widgets/home/")

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# Fix my_page_screen.dart
with open('lib/screens/my_page_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import '../age_picker_sheet.dart';", "import '../widgets/age_picker_sheet.dart';")
content = content.replace("import 'mypage/", "import '../widgets/mypage/")

with open('lib/screens/my_page_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# Fix legal_info_screen.dart
with open('lib/screens/settings/legal_info_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import '../../legal_terms_content.dart';", "import '../../widgets/legal_terms_content.dart';")

with open('lib/screens/settings/legal_info_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
