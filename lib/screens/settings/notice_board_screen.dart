import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class _Notice {
  final String title;
  final String date;
  final String content;
  final bool isNew;

  const _Notice({
    required this.title,
    required this.date,
    required this.content,
    this.isNew = false,
  });
}

class NoticeBoardScreen extends StatelessWidget {
  const NoticeBoardScreen({super.key});

  static const List<_Notice> _notices = [
    _Notice(
      title: '알려드림 서비스 정식 오픈 안내',
      date: '2026.07.01',
      content:
          '안녕하세요, 알려드림입니다.\n\n청년들을 위한 지역별 맞춤 혜택 큐레이션 서비스가 '
          '정식으로 오픈되었습니다. 인천 지역을 시작으로 점차 서비스 지역을 확대할 예정이니 '
          '많은 관심 부탁드립니다.',
      isNew: true,
    ),
    _Notice(
      title: '혜택 달력 기능 업데이트 안내',
      date: '2026.07.03',
      content:
          '혜택 달력에서 기간형(시작일~종료일) 일정 등록 기능이 추가되었습니다. '
          '또한 하루에 여러 혜택이 등록되어도 깔끔한 보라색 밑줄 마커로 표시되도록 개선했습니다.',
      isNew: true,
    ),
    _Notice(
      title: '개인정보 처리방침 개정 안내',
      date: '2026.06.20',
      content:
          '서비스 품질 향상을 위해 개인정보 처리방침 일부가 개정되었습니다. '
          '자세한 내용은 설정 > 법적 정보 화면에서 확인하실 수 있습니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('공지사항')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _notices.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notice = _notices[index];
          return ListTile(
            title: Row(
              children: [
                if (notice.isNew)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                Expanded(
                  child: Text(notice.title, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            subtitle: Text(notice.date),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _NoticeDetailScreen(notice: notice),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NoticeDetailScreen extends StatelessWidget {
  final _Notice notice;
  const _NoticeDetailScreen({required this.notice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('공지사항')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notice.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              notice.date,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const Divider(height: 32),
            Text(notice.content, style: const TextStyle(height: 1.6)),
          ],
        ),
      ),
    );
  }
}