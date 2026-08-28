import re

with open('lib/data/storage_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add cloud_firestore and firebase_auth imports
imports = """import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
"""
content = content.replace("import 'package:flutter_secure_storage/flutter_secure_storage.dart';\nimport 'package:shared_preferences/shared_preferences.dart';", imports)

# Update toggleWishlist
toggle_logic = """
  Future<void> toggleWishlist(String benefitId) async {
    final current = Set<String>.from(wishlistNotifier.value);
    if (current.contains(benefitId)) {
      current.remove(benefitId);
    } else {
      current.add(benefitId);
    }
    wishlistNotifier.value = current;
    await _prefs.setStringList(_wishlistKey, current.toList());
    
    // 클라우드 동기화 (로그인 된 경우)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'wishlist': current.toList(),
        });
      } catch (e) {
        // 무시 (오프라인이거나 DB 문서가 없는 경우)
      }
    }
  }
"""
content = re.sub(r'  Future<void> toggleWishlist\(String benefitId\) async \{.*?  \}', toggle_logic, content, flags=re.DOTALL)

with open('lib/data/storage_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
