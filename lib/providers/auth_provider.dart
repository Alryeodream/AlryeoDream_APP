import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as fAuth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import '../data/storage_service.dart';
import 'settings_provider.dart';

/// 로그인/회원가입 전 과정에서 화면 전환을 결정하는 단계.
/// AuthProvider.status 를 구독해서 라우팅을 분기한다.
enum AuthStatus {
  loading, // 앱 시작 시 로컬 저장소 확인 중
  loggedOut, // 로그인 안 된 상태 -> 로그인 화면
  needsTermsAgreement, // 소셜 로그인은 했지만 약관 동의 전 -> 약관 화면
  needsSignUp, // 약관 동의는 했지만 회원가입 폼 미완료 -> 회원가입 화면
  loggedIn, // 모든 절차 완료 -> 홈 화면
}

/// 로그인/회원가입/이메일 인증 등 인증 관련 전역 상태를 관리하는 Provider.
/// 앱 전역에서 참조 빈도가 높은 데이터이므로 (1차의 ValueNotifier 방식과 달리)
/// Provider(ChangeNotifier) 패턴을 사용해 유지보수성을 확보한다.
class AuthProvider extends ChangeNotifier {
  static const String _userKey = 'auth_user';
  static const String _termsAgreedKey = 'auth_terms_agreed';

  AppUser? _user;
  bool _termsAgreed = false;
  AuthStatus _status = AuthStatus.loading;

  // 이메일 인증 시뮬레이션용 임시 코드 저장
  String? _pendingVerificationCode;

  AppUser? get user => _user;
  bool get termsAgreed => _termsAgreed;
  AuthStatus get status => _status;
  bool get isLoggedIn => _status == AuthStatus.loggedIn;

  static const _storage = FlutterSecureStorage();
  late SharedPreferences _prefs;

  /// main() 에서 앱 시작 시 1회 호출
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    _termsAgreed = _prefs.getBool(_termsAgreedKey) ?? false;

    try {
      final userRaw = await _storage.read(key: _userKey);
      if (userRaw != null) {
        _user = AppUser.fromJson(jsonDecode(userRaw));
        
        if (kIsWeb && _user!.provider == SocialProvider.kakao) {
          try {
            await UserApi.instance.loginWithKakaoAccount();
          } catch (e) {
            debugPrint('Web Kakao auto-login failed: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('AuthProvider init error: $e');
      await _storage.delete(key: _userKey);
    }

    _recomputeStatus();
  }

  void _recomputeStatus() {
    if (_user == null) {
      _status = AuthStatus.loggedOut;
    } else if (!_termsAgreed) {
      _status = AuthStatus.needsTermsAgreement;
    } else if (!_user!.profileCompleted) {
      // 이메일 인증만으로는 넘어가지 않고, 닉네임/나이/알림동의까지
      // '가입 완료' 버튼을 눌러야만 다음 단계로 진행됨
      _status = AuthStatus.needsSignUp;
    } else {
      _status = AuthStatus.loggedIn;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // 1. 소셜 로그인
  // ---------------------------------------------------------------------

  /// 소셜 로그인 버튼 클릭 시 호출.
  /// 실제 서비스에서는 각 SDK(Kakao/Naver/Google/Apple)의 OAuth 흐름을 타지만,
  /// 여기서는 카카오 SDK를 연동하여 처리합니다.
  Future<void> loginWithSocial(SocialProvider provider) async {
    if (provider == SocialProvider.kakao) {
      await _loginWithKakao();
      return;
    }
    if (provider == SocialProvider.google) {
      await _loginWithGoogle();
      return;
    }
    if (provider == SocialProvider.naver) {
      await _loginWithNaver();
      return;
    }
    if (provider == SocialProvider.guest) {
      await _loginWithGuest();
      return;
    }

    debugPrint('지원하지 않는 소셜 로그인: $provider');
  }

  Future<void> _loginWithKakao() async {
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
  }

  bool _isGoogleInitialized = false;

  Future<void> _loginWithGoogle() async {
    try {
      if (!_isGoogleInitialized) {
        if (kIsWeb) {
          await GoogleSignIn.instance.initialize(
            clientId: '974397977561-dl7onddh39uqg9dhegore257to859cfk.apps.googleusercontent.com',
          );
        }
        _isGoogleInitialized = true;
      }

      final GoogleSignInAccount? account = await GoogleSignIn.instance.authenticate();
      if (account == null) return;
      
      final GoogleSignInAuthentication auth = account.authentication;
      final String? idToken = auth.idToken;
      
      if (idToken == null) throw Exception('Google idToken is null');

      final fAuth.OAuthCredential credential = fAuth.GoogleAuthProvider.credential(
        idToken: idToken,
      );
      
      final fAuth.UserCredential userCredential = await fAuth.FirebaseAuth.instance.signInWithCredential(credential);
      
      await _handleFirebaseUser(userCredential.user!, SocialProvider.google, account.displayName ?? 'Google User', account.email);
    } catch (e) {
      debugPrint('Google login error: $e');
    }
  }

  Future<void> _loginWithNaver() async {
    try {
      final result = await FlutterNaverLogin.logIn();
      if (result.status.toString() == 'NaverLoginStatus.loggedIn') {
        final account = await FlutterNaverLogin.getCurrentAccount();
        final String userId = account.id ?? '';
        final String userName = account.name ?? 'Naver User';
        final String userEmail = account.email ?? 'naver@example.com';
        
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
  }

  Future<void> _loginWithGuest() async {
    try {
      final userCredential = await fAuth.FirebaseAuth.instance.signInAnonymously();
      await _handleFirebaseUser(userCredential.user!, SocialProvider.guest, '게스트 사용자', 'guest_${userCredential.user!.uid}@youthbenefits.local');
    } catch (e) {
      debugPrint('Guest login error: $e');
    }
  }

  Future<void> _handleFirebaseUser(fAuth.User fbUser, SocialProvider provider, String fallbackName, String fallbackEmail) async {
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
  }

  // Deprecated dummy handler removed

  Future<void> logout() async {
    _user = null;
    _termsAgreed = false;
    await _storage.delete(key: _userKey);
    await _prefs.remove(_termsAgreedKey);
    await fAuth.FirebaseAuth.instance.signOut();
    _recomputeStatus();
  }

  // ---------------------------------------------------------------------
  // 2. 약관 동의 (끝까지 스크롤해야만 호출 가능하도록 UI에서 제어)
  // ---------------------------------------------------------------------

  Future<void> agreeToTerms() async {
    _termsAgreed = true;
    await _prefs.setBool(_termsAgreedKey, true);
    _recomputeStatus();
  }

  // ---------------------------------------------------------------------
  // 3. 회원가입 폼 (이름 / 심야 알림 동의)
  // ---------------------------------------------------------------------

  Future<void> updateProfile({
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
  }

  /// 마이페이지에서 닉네임만 단독으로 수정할 때 사용
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
  }


  /// 마이페이지 프로필 사진 변경.
  /// 웹/모바일 모두에서 동작하도록 이미지를 base64 문자열로 인코딩해 저장한다.
  /// (원본 기획 문서의 "프로필 이미지 저장 용량 초과" 트러블슈팅 항목 참고 —
  ///  추후 고화질 이미지가 많아지면 IndexedDB/로컬 파일 시스템 경로로 전환 필요)
  Future<void> updateProfileImage(String base64Image) async {
    if (_user == null) return;
    _user!.profileImagePath = base64Image;
    await _persistUser();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // 4. 이메일 인증
  // ---------------------------------------------------------------------

  /// 인증 메일 발송 시뮬레이션. 실제로는 서버 API 호출 + 메일 발송.
  Future<void> sendVerificationEmail(String email) async {
    if (_user == null) return;
    _user!.email = email;
    _pendingVerificationCode =
        (100000 + Random().nextInt(899999)).toString(); // 6자리 코드 시뮬레이션
    await _persistUser();
    notifyListeners();

    // 실제 환경에서는 이메일로 발송되고 여기서 콘솔에 남기지 않음.
    // 데모 편의를 위해 디버그 콘솔에만 출력.
    debugPrint('[DEV ONLY] 인증코드: $_pendingVerificationCode');
  }

  /// 사용자가 입력한 인증 코드 확인
  bool verifyEmailCode(String inputCode) {
    if (_pendingVerificationCode == null) return false;
    final isMatch = _pendingVerificationCode == inputCode.trim();
    if (isMatch && _user != null) {
      _user!.emailVerified = true;
      _pendingVerificationCode = null;
      _persistUser();
      notifyListeners(); // 이메일 인증 완료 표시만 갱신, 화면 전환은 하지 않음
    }
    return isMatch;
  }

  Future<void> _persistUser() async {
    if (_user == null) return;
    await _storage.write(key: _userKey, value: jsonEncode(_user!.toJson()));
  }
}