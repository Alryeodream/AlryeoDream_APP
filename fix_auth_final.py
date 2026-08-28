import re

with open("lib/providers/auth_provider.dart", "r") as f:
    content = f.read()

# Fix Google SignIn
google_fix = """      final account = await GoogleSignIn.instance.authenticate();
      final auth = await account.authentication;
      
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );"""
content = re.sub(r'      final account = await GoogleSignIn\.instance\.signIn\(\);\n      if \(account == null\) return;\n      \n      final auth = await account\.authentication;\n      \n      final credential = firebase_auth\.GoogleAuthProvider\.credential\(\n        accessToken: auth\.accessToken,\n        idToken: auth\.idToken,\n      \);', google_fix, content, flags=re.DOTALL)

with open("lib/providers/auth_provider.dart", "w") as f:
    f.write(content)

