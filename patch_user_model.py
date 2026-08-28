import re

with open('lib/models/user.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add new fields to AppUser
fields = """
  bool profileCompleted; // 회원가입 폼(닉네임/나이/알림동의) 제출 완료 여부
  bool nightNotificationConsent; // 심야(21시~08시) 알림 수신 동의
  String? profileImagePath;
  
  // 클라우드 동기화 필드
  List<String> wishlist;
  int themeModeIndex;
  double textScale;
"""
content = re.sub(r'  bool profileCompleted;.*String\? profileImagePath;', fields, content, flags=re.DOTALL)

# Add to constructor
constructor = """
    this.nightNotificationConsent = false,
    this.profileImagePath,
    this.wishlist = const [],
    this.themeModeIndex = 0,
    this.textScale = 1.0,
"""
content = re.sub(r'    this\.nightNotificationConsent = false,.*this\.profileImagePath,', constructor, content, flags=re.DOTALL)

# Add to toJson
to_json = """
        'nightNotificationConsent': nightNotificationConsent,
        'profileImagePath': profileImagePath,
        'wishlist': wishlist,
        'themeModeIndex': themeModeIndex,
        'textScale': textScale,
"""
content = re.sub(r"        'nightNotificationConsent': nightNotificationConsent,.*'profileImagePath': profileImagePath,", to_json, content, flags=re.DOTALL)

# Add to fromJson
from_json = """
      nightNotificationConsent: json['nightNotificationConsent'] as bool? ?? false,
      profileImagePath: json['profileImagePath'] as String?,
      wishlist: (json['wishlist'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      themeModeIndex: json['themeModeIndex'] as int? ?? 0,
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
"""
content = re.sub(r"      nightNotificationConsent:.*?json\['profileImagePath'\] as String\?,", from_json, content, flags=re.DOTALL)

with open('lib/models/user.dart', 'w', encoding='utf-8') as f:
    f.write(content)
