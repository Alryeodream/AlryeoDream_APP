import re

with open('lib/providers/auth_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Update _handleFirebaseUser to fetch and apply wishlist/settings
handle_user = """
    String name = fallbackName;
    String email = fallbackEmail;
    int age = 24;
    bool profileCompleted = false;
    List<String> wishlist = [];
    int themeModeIndex = 0;
    double textScale = 1.0;
    
    if (docSnap.exists) {
      final data = docSnap.data()!;
      name = data['name'] ?? fallbackName;
      email = data['email'] ?? fallbackEmail;
      age = data['age'] ?? 24;
      profileCompleted = data['profileCompleted'] ?? false;
      wishlist = (data['wishlist'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
      themeModeIndex = data['themeModeIndex'] ?? 0;
      textScale = (data['textScale'] as num?)?.toDouble() ?? 1.0;
    } else {
      await docRef.set({
        'name': name,
        'email': email,
        'age': age,
        'provider': provider.name,
        'profileCompleted': false,
        'wishlist': wishlist,
        'themeModeIndex': themeModeIndex,
        'textScale': textScale,
      });
    }
    
    _user = AppUser(
      id: fbUser.uid,
      provider: provider,
      name: name,
      age: age,
      email: email,
      emailVerified: true,
      wishlist: wishlist,
      themeModeIndex: themeModeIndex,
      textScale: textScale,
    );
    _user!.profileCompleted = profileCompleted;
"""
content = re.sub(r'    String name = fallbackName;.*?_user!\.profileCompleted = profileCompleted;', handle_user, content, flags=re.DOTALL)

with open('lib/providers/auth_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)
