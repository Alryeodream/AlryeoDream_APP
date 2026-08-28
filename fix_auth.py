import re

with open("lib/providers/auth_provider.dart", "r") as f:
    content = f.read()

# Fix fAuth prefix
content = content.replace("as fAuth;", "as firebase_auth;")
content = content.replace("fAuth.", "firebase_auth.")

# Fix unused imports
content = content.replace("import 'package:flutter/services.dart';\n", "")

# Fix unused variables
content = content.replace("bool isNewUser = !docSnap.exists;", "")

# Fix string interps
content = content.replace("'kakao_${userId}@youthbenefits.local'", "'kakao_$userId@youthbenefits.local'")
content = content.replace("'kakao_secret_${userId}'", "'kakao_secret_$userId'")

# Fix Google SignIn
google_fix = """      final account = await GoogleSignIn.instance.signIn();
      if (account == null) return;
      
      final auth = await account.authentication;
      
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );"""
content = re.sub(r'      final GoogleSignInAccount account = await GoogleSignIn\.instance\.authenticate\(\);\n      final GoogleSignInAuthentication auth = await account\.authentication;\n      \n      final firebase_auth\.OAuthCredential credential = firebase_auth\.GoogleAuthProvider\.credential\(\n        accessToken: auth\.accessToken,\n        idToken: auth\.idToken,\n      \);', google_fix, content, flags=re.DOTALL)

with open("lib/providers/auth_provider.dart", "w") as f:
    f.write(content)

