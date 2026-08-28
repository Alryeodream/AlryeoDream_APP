import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// 이용약관 및 개인정보 처리방침 본문 위젯.
/// - 회원가입 시 TermsAgreementScreen (스크롤 강제 동의)
/// - 설정 > 법적 정보 화면 (조회 전용)
/// 두 곳에서 공용으로 사용한다.
class LegalTermsContent extends StatelessWidget {
  const LegalTermsContent({super.key});

  static const List<(String, String)> sections = [
    (
      '제1조 (목적)',
      '이 약관은 알려드림(이하 "회사")이 제공하는 청년 정책 혜택 큐레이션 서비스(이하 "서비스")의 '
          '이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.',
    ),
    (
      '제2조 (용어의 정의)',
      '① "서비스"란 회사가 제공하는 청년 혜택 정보 큐레이션, 달력 관리, 맞춤 추천 등 일체의 기능을 말합니다.\n'
          '② "이용자"란 이 약관에 따라 회사가 제공하는 서비스를 이용하는 회원을 말합니다.',
    ),
    (
      '제3조 (약관의 효력 및 변경)',
      '① 이 약관은 서비스 화면에 게시하거나 기타의 방법으로 이용자에게 공지함으로써 효력을 발생합니다.\n'
          '② 회사는 관련 법령을 위배하지 않는 범위에서 이 약관을 변경할 수 있습니다.',
    ),
    (
      '제4조 (개인정보의 수집 및 이용)',
      '회사는 서비스 제공을 위해 이름, 만 나이, 이메일 주소, 거주 지역 등 최소한의 개인정보를 수집하며, '
          '수집된 정보는 맞춤형 혜택 추천 및 일정 알림 발송 목적으로만 이용됩니다.',
    ),
    (
      '제5조 (심야 알림 수신 동의)',
      '이용자가 별도로 동의하는 경우, 21시부터 익일 08시 사이에도 마감 임박 혜택에 대한 알림을 '
          '수신할 수 있습니다. 이 동의는 언제든지 설정 화면에서 철회할 수 있습니다.',
    ),
    (
      '제6조 (이용자의 의무)',
      '이용자는 관계 법령, 이 약관의 규정, 이용안내 및 서비스와 관련하여 공지한 주의사항을 '
          '준수하여야 하며, 기타 회사의 업무에 방해되는 행위를 하여서는 안 됩니다.',
    ),
    (
      '제7조 (면책조항)',
      '회사는 천재지변 또는 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우에는 '
          '서비스 제공에 관한 책임이 면제됩니다. 또한 회사는 이용자가 게재한 정보의 신뢰도, '
          '정확성에 대해 책임을 지지 않습니다.',
    ),
    (
      '제8조 (분쟁 해결)',
      '이 약관과 관련하여 분쟁이 발생한 경우, 회사와 이용자는 분쟁의 원만한 해결을 위해 '
          '필요한 노력을 다하여야 하며, 이를 위해서도 해결되지 않을 경우 관할 법원에 소를 '
          '제기할 수 있습니다.\n\n부칙: 이 약관은 공고한 날로부터 시행합니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이용약관 및 개인정보 처리방침',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 20),
        for (final (title, body) in sections) ...[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentPurple,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}