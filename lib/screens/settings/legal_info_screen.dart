import 'package:flutter/material.dart';
import '../../widgets/legal_terms_content.dart';

/// 설정 > 법적 정보에서 접근하는 조회 전용 화면 (동의 버튼 없음)
class LegalInfoScreen extends StatelessWidget {
  const LegalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이용약관 및 개인정보 처리방침')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: LegalTermsContent(),
      ),
    );
  }
}