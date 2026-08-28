/// 청년 혜택 정보를 담는 모델 클래스
class Benefit {
  final String id;
  final String title; // 혜택명 (예: 청년 월세 지원)
  final String organization; // 주관 기관 (예: 인천시청)
  final String category; // 카테고리 (주거, 교육, 창업 등)
  final String region; // 지원 지역 (예: 인천, 전국형은 '전국')
  final String url; // 원본 웹사이트 링크 (복지로, 마이홈 등)
  final int minAge; // 최소 만 나이
  final int maxAge; // 최대 만 나이
  final String targetGender; // '무관' | '남' | '여'
  final String description;
  final bool isNationwide; // 전국 대상 여부 (지역 필터와 무관하게 항상 노출)
  final DateTime? endDate; // 마감일 (마감 임박 알림용)

  const Benefit({
    required this.id,
    required this.title,
    required this.organization,
    required this.category,
    required this.region,
    required this.url,
    required this.minAge,
    required this.maxAge,
    required this.targetGender,
    this.description = '',
    this.isNationwide = false,
    this.endDate,
  });

  /// 사용자가 이 혜택의 대상 조건에 부합하는지 확인
  bool matches({required int age, required String gender}) {
    final ageOk = age >= minAge && age <= maxAge;
    final genderOk = targetGender == '무관' || targetGender == gender;
    return ageOk && genderOk;
  }

  /// 전국 대상 혜택이면 어떤 지역을 선택했든 항상 매칭되고,
  /// 그 외에는 지역이 정확히 일치할 때만 매칭됨
  bool matchesRegion(String selectedRegion) {
    return isNationwide || region == selectedRegion;
  }

  factory Benefit.fromJson(Map<String, dynamic> json) {
    bool nationwide = false;
    String regionName = '전국';
    if (json['benefit_regions'] != null && (json['benefit_regions'] as List).isNotEmpty) {
      final regions = json['benefit_regions'] as List;
      final firstRegion = regions.first;
      if (firstRegion['sido_id'] == null) {
        nationwide = true;
      } else {
        regionName = firstRegion['sido']?['name'] ?? '알 수 없음';
      }
    } else {
      nationwide = true;
    }

    String parsedGender = '무관';
    if (json['target_gender'] == 'MALE') parsedGender = '남';
    if (json['target_gender'] == 'FEMALE') parsedGender = '여';

    return Benefit(
      id: json['benefit_id']?.toString() ?? '',
      title: json['title'] ?? '',
      organization: json['provider'] ?? '',
      category: json['category']?['name'] ?? '기타',
      region: regionName,
      url: json['site_url'] ?? '',
      minAge: json['min_age'] ?? 0,
      maxAge: json['max_age'] ?? 99,
      targetGender: parsedGender,
      description: json['description'] ?? '',
      isNationwide: nationwide,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
    );
  }
}

/// 홈 화면 / 맞춤검색 결과 정렬 기준
enum BenefitSortOption { latest, viewCount, category }

extension BenefitSortOptionLabel on BenefitSortOption {
  String get label {
    switch (this) {
      case BenefitSortOption.latest:
        return '최신순';
      case BenefitSortOption.viewCount:
        return '조회수순';
      case BenefitSortOption.category:
        return '카테고리순';
    }
  }
}

/// 달력에 등록되는 개별 일정 이벤트
class CalendarEvent {
  final String benefitId;
  final String title;
  final String url;

  const CalendarEvent({
    required this.benefitId,
    required this.title,
    required this.url,
  });

  Map<String, dynamic> toJson() => {
        'benefitId': benefitId,
        'title': title,
        'url': url,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      benefitId: json['benefitId'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
    );
  }
}

/// 데모/개발용 목데이터
/// 실제 서비스에서는 서버(API) 또는 로컬 DB에서 불러오도록 교체 예정
final List<Benefit> demoBenefits = [
  Benefit(
    id: 'benefit_001',
    title: '청년 월세 특별지원',
    organization: '인천광역시청',
    category: '주거',
    region: '인천',
    url: 'https://www.bokjiro.go.kr',
    minAge: 19,
    maxAge: 34,
    targetGender: '무관',
    description: '무주택 청년 1인 가구를 위한 월 최대 20만원 월세 지원 사업입니다.',
  ),
  Benefit(
    id: 'benefit_002',
    title: '청년 창업 자금 지원',
    organization: '인천창조경제혁신센터',
    category: '창업',
    region: '인천',
    url: 'https://www.myhome.go.kr',
    minAge: 20,
    maxAge: 39,
    targetGender: '무관',
    description: '예비 창업자를 위한 최대 5천만원 저리 창업 자금 지원.',
  ),
  Benefit(
    id: 'benefit_003',
    title: '여성 청년 취업 장려금',
    organization: '인천여성가족재단',
    category: '취업',
    region: '인천',
    url: 'https://www.bokjiro.go.kr',
    minAge: 18,
    maxAge: 29,
    targetGender: '여',
    description: '여성 청년 구직자 대상 3개월간 월 30만원 취업 장려금 지급.',
  ),
  Benefit(
    id: 'benefit_004',
    title: '청년 교육비 바우처',
    organization: '인천광역시교육청',
    category: '교육',
    region: '인천',
    url: 'https://www.bokjiro.go.kr',
    minAge: 19,
    maxAge: 24,
    targetGender: '무관',
    description: '자격증 및 어학 시험 응시료를 지원하는 교육 바우처 사업.',
  ),
  // 전국 대상 혜택: 지역 필터와 무관하게 항상 검색 결과에 포함됨
  Benefit(
    id: 'benefit_005',
    title: '청년 월세 지원 (전국형)',
    organization: '국토교통부',
    category: '주거',
    region: '전국',
    url: 'https://www.bokjiro.go.kr',
    minAge: 19,
    maxAge: 34,
    targetGender: '무관',
    description: '전국 단위로 운영되는 청년 월세 지원 사업으로, 거주 지역과 무관하게 신청 가능합니다.',
    isNationwide: true,
  ),
  Benefit(
    id: 'benefit_006',
    title: '청년도약계좌',
    organization: '금융위원회',
    category: '금융',
    region: '전국',
    url: 'https://www.bokjiro.go.kr',
    minAge: 19,
    maxAge: 34,
    targetGender: '무관',
    description: '5년 만기 자산형성을 지원하는 전국 단위 청년 정책금융 상품입니다.',
    isNationwide: true,
  ),
];