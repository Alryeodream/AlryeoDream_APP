/// 소셜 로그인 제공자 종류
enum SocialProvider { kakao, naver, google, apple, guest }

extension SocialProviderLabel on SocialProvider {
  String get label {
    switch (this) {
      case SocialProvider.kakao:
        return '카카오';
      case SocialProvider.naver:
        return '네이버';
      case SocialProvider.google:
        return '구글';
      case SocialProvider.apple:
        return '애플';
      case SocialProvider.guest:
        return '게스트';
    }
  }
}

/// 앱 사용자 정보 모델
class AppUser {
  final String id;
  final SocialProvider provider;
  String name;
  int age; // 회원가입 폼에서 사용자가 직접 입력/수정 가능
  String email;
  bool emailVerified;

  bool profileCompleted; // 회원가입 폼(닉네임/나이/알림동의) 제출 완료 여부
  bool nightNotificationConsent; // 심야(21시~08시) 알림 수신 동의
  String? profileImagePath;
  
  // 클라우드 동기화 필드
  List<String> wishlist;
  int themeModeIndex;
  double textScale;


  AppUser({
    required this.id,
    required this.provider,
    required this.name,
    required this.age,
    required this.email,
    this.emailVerified = false,
    this.profileCompleted = false,

    this.nightNotificationConsent = false,
    this.profileImagePath,
    this.wishlist = const [],
    this.themeModeIndex = 0,
    this.textScale = 1.0,

  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'provider': provider.name,
        'name': name,
        'age': age,
        'email': email,
        'emailVerified': emailVerified,
        'profileCompleted': profileCompleted,

        'nightNotificationConsent': nightNotificationConsent,
        'profileImagePath': profileImagePath,
        'wishlist': wishlist,
        'themeModeIndex': themeModeIndex,
        'textScale': textScale,

      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      provider: SocialProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => SocialProvider.kakao,
      ),
      name: json['name'] as String,
      age: json['age'] as int,
      email: json['email'] as String,
      emailVerified: json['emailVerified'] as bool? ?? false,
      profileCompleted: json['profileCompleted'] as bool? ?? false,

      nightNotificationConsent: json['nightNotificationConsent'] as bool? ?? false,
      profileImagePath: json['profileImagePath'] as String?,
      wishlist: (json['wishlist'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      themeModeIndex: json['themeModeIndex'] as int? ?? 0,
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,

    );
  }
}