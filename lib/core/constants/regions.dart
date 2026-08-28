/// 전국 17개 시도 지역 목록.
/// 이전에는 custom_search_screen.dart 안에 정의되어 있고
/// home_screen.dart가 그걸 가져다 쓰는 구조라 소유권이 애매했음.
/// 이제 이 상수 파일이 '유일한 소유자'이며, 다른 화면은 여기서 import해서 사용함.
const List<String> kAllRegions = [
  '서울', '부산', '대구', '인천', '광주', '대전', '울산', '세종',
  '경기', '강원', '충북', '충남', '전북', '전남', '경북', '경남', '제주',
];

/// 현재 서비스 주력 지역.
/// 이 지역 외 지역 전용 혜택 검색 시 "준비중입니다!" 안내가 표시됨.
/// (전국 대상 혜택(Benefit.isNationwide)은 이 값과 무관하게 항상 검색됨)
const String kSupportedRegion = '인천';