import re

with open('lib/providers/benefit_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add cloud_firestore import
content = content.replace("import '../models/benefit.dart';", "import '../models/benefit.dart';\nimport 'package:cloud_firestore/cloud_firestore.dart';")

# Replace fetchBenefits logic
fetch_benefits_logic = """
  Future<void> fetchBenefits() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 클라우드 Firestore에서 데이터 가져오기
      final querySnapshot = await FirebaseFirestore.instance.collection('benefits').get();
      
      _benefits = querySnapshot.docs.map((doc) {
        final data = doc.data();
        // ID 누락 시 문서 ID 사용
        if (!data.containsKey('benefit_id')) {
          data['benefit_id'] = doc.id;
        }
        return Benefit.fromJson(data);
      }).toList();
      
    } catch (e) {
      debugPrint('Firestore 데이터 로드 실패, 로컬 에셋(assets/data) 폴백 시도: $e');
      try {
        final jsonString = await rootBundle.loadString('assets/data/benefits_data.json');
        _benefits = await compute(_parseBenefits, jsonString);
      } catch (assetError) {
        debugPrint('에셋 로드 실패, 데모 데이터 사용: $assetError');
        if (_benefits.isEmpty) {
          _benefits = demoBenefits;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
"""

content = re.sub(r'  Future<void> fetchBenefits\(\) async \{.*  \}\n\n  Future<List<Benefit>> fetchCustomBenefits', fetch_benefits_logic + "\n  Future<List<Benefit>> fetchCustomBenefits", content, flags=re.DOTALL)

with open('lib/providers/benefit_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)
