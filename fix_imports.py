import os
import glob

def replace_in_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Replace widgets/screens/home/ -> widgets/home/
    new_content = content.replace('widgets/screens/home/', 'widgets/home/')
    # 2. Replace widgets/screens/mypage/ -> widgets/mypage/
    new_content = new_content.replace('widgets/screens/mypage/', 'widgets/mypage/')
    # 3. Replace remaining widgets/screens/ -> screens/
    new_content = new_content.replace('widgets/screens/', 'screens/')
    
    if content != new_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated imports in {filepath}")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            replace_in_file(os.path.join(root, file))

# Also fix main.dart if it's in the root of lib
replace_in_file('lib/main.dart')
