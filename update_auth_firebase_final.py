import re

with open("lib/providers/auth_provider.dart", "r") as f:
    content = f.read()

# 1. Add Firebase imports
content = content.replace("import '../core/api_client.dart';", 
"""import 'package:firebase_auth/firebase_auth.dart' as fAuth;
import 'package:cloud_firestore/cloud_firestore.dart';""")

# 2. Replace _loginWithKakao
kakao_new = """  Future<void> _loginWithKakao() async {
    try {
      OAuthToken token;
      
      if (kIsWeb) {
        token = await UserApi.instance.loginWithKakaoAccount();
      } else {
        if (await isKakaoTalkInstalled()) {
          try {
            token = await UserApi.instance.loginWithKakaoTalk();
          } catch (error) {
            debugPrint('카카오톡으로 로그인 실패 $error');
            if (error is PlatformException && error.code == 'CANCELED') {
              return;
            }
            token = await UserApi.instance.loginWithKakaoAccount();
          }
        } else {
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      }
      
      debugPrint('카카오 로그인 성공: ${token.accessToken}');
      
      final User kakaoUser = await UserApi.instance.me();
      final String userName = kakaoUser.kakaoAccount?.profile?.nickname ?? 'Kakao User';
      final String userEmail = kakaoUser.kakaoAccount?.email ?? 'kakao@example.com';
      final String userId = kakaoUser.id.toString();
      
      final email = 'kakao_${userId}@youthbenefits.local';
      final password = 'kakao_secret_${userId}';
      
      fAuth.UserCredential userCredential;
      try {
        userCredential = await fAuth.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        userCredential = await fAuth.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      
      await _handleFirebaseUser(userCredential.user!, SocialProvider.kakao, userName, userEmail);
    } catch (e) {
      debugPrint('Kakao login error: $e');
    }
  }"""
content = re.sub(r'  Future<void> _loginWithKakao\(\) async \{.*?    \} catch \(e\) \{\n      debugPrint\(\'Kakao login error: \$e\'\);\n    \}\n  \}', kakao_new, content, flags=re.DOTALL)

# 3. Replace _loginWithGoogle
google_new = """  Future<void> _loginWithGoogle() async {
    try {
      if (!_isGoogleInitialized) {
        await GoogleSignIn.instance.initialize(
          clientId: kIsWeb
              ? '974397977561-dl7onddh39uqg9dhegore257to859cfk.apps.googleusercontent.com'
              : '974397977561-96ntjij2hd6tf5m6n6qva9l6j0m24vjp.apps.googleusercontent.com',
          serverClientId: kIsWeb
              ? null
              : '974397977561-dl7onddh39uqg9dhegore257to859cfk.apps.googleusercontent.com',
        );
        _isGoogleInitialized = true;
      }

      final GoogleSignInAccount? account = await GoogleSignIn.instance.authenticate();
      if (account == null) return;
      
      final GoogleSignInAuthentication auth = account.authentication;
      final String? idToken = auth.idToken;
      final String? accessToken = auth.accessToken;
      
      if (idToken == null) throw Exception('Google idToken is null');

      final fAuth.OAuthCredential credential = fAuth.GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      
      final fAuth.UserCredential userCredential = await fAuth.FirebaseAuth.instance.signInWithCredential(credential);
      
      await _handleFirebaseUser(userCredential.user!, SocialProvider.google, account.displayName ?? 'Google User', account.email);
    } catch (e) {
      debugPrint('Google login error: $e');
    }
  }"""
content = re.sub(r'  Future<void> _loginWithGoogle\(\) async \{.*?    \} catch \(e\) \{\n      debugPrint\(\'Google login error: \$e\'\);\n    \}\n  \}', google_new, content, flags=re.DOTALL)

# 4. Replace _loginWithNaver
naver_new = """  Future<void> _loginWithNaver() async {
    try {
      final result = await FlutterNaverLogin.logIn();
      if (result.status.toString() == 'NaverLoginStatus.loggedIn') {
        final account = await FlutterNaverLogin.currentAccount();
        final String userId = account.id;
        final String userName = account.name;
        final String userEmail = account.email;
        
        final email = 'naver_${userId}@youthbenefits.local';
        final password = 'naver_secret_${userId}';
        
        fAuth.UserCredential userCredential;
        try {
          userCredential = await fAuth.FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } catch (e) {
          userCredential = await fAuth.FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        }
        
        await _handleFirebaseUser(userCredential.user!, SocialProvider.naver, userName, userEmail);
      }
    } catch (e) {
      debugPrint('Naver login error: $e');
    }
  }"""
content = re.sub(r'  Future<void> _loginWithNaver\(\) async \{.*?    \} catch \(e\) \{\n      debugPrint\(\'Naver login error: \$e\'\);\n    \}\n  \}', naver_new, content, flags=re.DOTALL)


# 5. Replace _handleLoginResponse with _handleFirebaseUser
firebase_handler = """  Future<void> _handleFirebaseUser(fAuth.User fbUser, SocialProvider provider, String fallbackName, String fallbackEmail) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(fbUser.uid);
    final docSnap = await docRef.get();
    
    bool isNewUser = !docSnap.exists;
    String name = fallbackName;
    String email = fallbackEmail;
    int age = 24;
    bool profileCompleted = false;
    
    if (docSnap.exists) {
      final data = docSnap.data()!;
      name = data['name'] ?? fallbackName;
      email = data['email'] ?? fallbackEmail;
      age = data['age'] ?? 24;
      profileCompleted = data['profileCompleted'] ?? false;
    } else {
      await docRef.set({
        'name': name,
        'email': email,
        'age': age,
        'provider': provider.name,
        'profileCompleted': false,
      });
    }
    
    _user = AppUser(
      id: fbUser.uid,
      provider: provider,
      name: name,
      age: age,
      email: email,
      emailVerified: true,
    );
    _user!.profileCompleted = profileCompleted;
    
    await _persistUser();
    _recomputeStatus();
  }

  // Deprecated dummy handler
  Future<void> _handleLoginResponse(dynamic response, SocialProvider provider) async {
    // Legacy mock logic discarded
  }"""
content = re.sub(r'  Future<void> _handleLoginResponse\(dynamic response, SocialProvider provider\) async \{.*?      _recomputeStatus\(\);\n    \}\n  \}', firebase_handler, content, flags=re.DOTALL)

# 6. Replace updateProfile
update_profile_new = """  Future<void> updateProfile({
    required String name,
    required int age,
    required bool nightNotificationConsent,
  }) async {
    if (_user == null) return;
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.id).update({
        'name': name,
        'age': age,
        'nightNotificationConsent': nightNotificationConsent,
        'profileCompleted': true,
      });
    } catch (e) {
      debugPrint('Firestore update failed: $e');
    }
    
    _user!.name = name;
    _user!.age = age;
    _user!.nightNotificationConsent = nightNotificationConsent;
    _user!.profileCompleted = true;
    await _persistUser();
    _recomputeStatus();
  }"""
content = re.sub(r'  Future<void> updateProfile\(\{.*?_recomputeStatus\(\);\n  \}', update_profile_new, content, flags=re.DOTALL)

# 7. Replace updateNickname and updateBasicInfo
update_info_new = """  /// 마이페이지에서 닉네임만 단독으로 수정할 때 사용
  Future<void> updateNickname(String nickname) async {
    if (_user == null || nickname.trim().isEmpty) return;
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.id).update({
        'name': nickname.trim(),
      });
    } catch (e) {}

    _user!.name = nickname.trim();
    await _persistUser();
    notifyListeners();
  }

  /// 마이페이지에서 닉네임과 나이를 함께 수정할 때 사용
  Future<void> updateBasicInfo({
    required String nickname,
    required int age,
  }) async {
    if (_user == null) return;
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.id).update({
        'name': nickname.trim().isEmpty ? _user!.name : nickname.trim(),
        'age': age,
      });
    } catch (e) {}

    if (nickname.trim().isNotEmpty) _user!.name = nickname.trim();
    _user!.age = age;
    await _persistUser();
    notifyListeners();
  }"""
content = re.sub(r'  /// 마이페이지에서 닉네임만 단독으로 수정할 때 사용.*?notifyListeners\(\);\n  \}', update_info_new, content, flags=re.DOTALL)

# 8. Restore Firebase Auth signOut
logout_new = """  Future<void> logout() async {
    _user = null;
    _termsAgreed = false;
    await _storage.delete(key: _userKey);
    await _prefs.remove(_termsAgreedKey);
    await fAuth.FirebaseAuth.instance.signOut();
    _recomputeStatus();
  }"""
content = re.sub(r'  Future<void> logout\(\) async \{.*?_recomputeStatus\(\);\n  \}', logout_new, content, flags=re.DOTALL)

# 9. Restore loginWithSocial fallback for others to _handleLoginResponse
login_social_fallback = """    // 다른 소셜 제공자는 기존 모의 로그인 사용
    _handleLoginResponse(null, provider);"""
content = re.sub(r'    // 다른 소셜 제공자는 기존 모의 로그인 사용.*?      debugPrint\(\'Login failed: \$e\'\);\n    \}', login_social_fallback, content, flags=re.DOTALL)


with open("lib/providers/auth_provider.dart", "w") as f:
    f.write(content)

