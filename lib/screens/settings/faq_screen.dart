import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const List<(String, String)> _faqs = [
    (
      'Q. 혜택 알림은 어떻게 설정하나요?',
      '회원가입 시 심야 알림(21시~08시) 수신 동의를 하시면 마감이 임박한 혜택에 대한 알림을 '
          '언제든지 받아보실 수 있습니다. 수신 동의 여부는 마이페이지에서 다시 확인할 수 있습니다.',
    ),
    (
      'Q. 인천 외 지역도 서비스 이용이 가능한가요?',
      '현재는 인천 지역 청년 혜택만 우선 서비스하고 있습니다. 다른 지역은 순차적으로 확대할 '
          '예정이며, 맞춤검색에서 인천 외 지역 선택 시 "준비중입니다!" 안내가 표시됩니다.',
    ),
    (
      'Q. 찜한 혜택은 어디서 확인하나요?',
      '홈 화면에서 하트 아이콘을 눌러 찜한 혜택은 마이페이지 하단의 "찜한 혜택" 섹션에서 '
          '모아볼 수 있습니다.',
    ),
    (
      'Q. 달력에 등록한 일정은 어떻게 삭제하나요?',
      '혜택 달력 화면에서 해당 일정을 선택한 뒤 휴지통 아이콘을 누르면 "해당 날짜만 삭제"와 '
          '"전체 일정 삭제" 중 선택할 수 있습니다.',
    ),
    (
      'Q. 프로필 사진은 어떻게 바꾸나요?',
      '마이페이지 상단 프로필 영역의 카메라 아이콘을 눌러 갤러리에서 원하는 사진을 선택하면 '
          '바로 반영됩니다.',
    ),
    (
      'Q. 글자 크기나 테마는 어디서 바꾸나요?',
      '마이페이지 상단의 설정(톱니바퀴) 아이콘을 눌러 설정 화면으로 이동하면, 테마(시스템/라이트/'
          '다크)와 글자 크기(1.0x~1.5x)를 조절할 수 있습니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자주 묻는 질문')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _faqs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final (question, answer) = _faqs[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              title: Text(
                question,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              iconColor: AppColors.accentPurple,
              collapsedIconColor: Colors.grey,
              childrenPadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  answer,
                  style: TextStyle(
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}