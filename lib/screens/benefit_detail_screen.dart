import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/benefit.dart';
import '../../data/storage_service.dart';
import '../../core/constants/app_colors.dart';

class BenefitDetailScreen extends StatefulWidget {
  final Benefit benefit;

  const BenefitDetailScreen({super.key, required this.benefit});

  @override
  State<BenefitDetailScreen> createState() => _BenefitDetailScreenState();
}

class _BenefitDetailScreenState extends State<BenefitDetailScreen> {
  final StorageService _storage = StorageService.instance;

  @override
  void initState() {
    super.initState();
    // 상세화면 진입 시 조회수 1 증가 (조회수순 정렬에 사용)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _storage.incrementViewCount(widget.benefit.id);
    });
  }

  Future<void> _openOriginalSite() async {
    // 외부 사이트로 이동할 때도 조회수(또는 관심도)를 증가시켜 랭킹에 반영
    _storage.incrementViewCount(widget.benefit.id);
    
    final uri = Uri.parse(widget.benefit.url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('링크를 열 수 없습니다: ${widget.benefit.url}')),
      );
    }
  }

  String get _targetSummary {
    final benefit = widget.benefit;
    final ageRange = '만 ${benefit.minAge}~${benefit.maxAge}세';
    final gender = benefit.targetGender == '무관' ? '성별 무관' : benefit.targetGender;
    final region = benefit.isNationwide ? '전국 대상' : benefit.region;
    return '$ageRange · $gender · $region';
  }

  @override
  Widget build(BuildContext context) {
    final benefit = widget.benefit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('혜택 상세'),
        actions: [
          ValueListenableBuilder<Set<String>>(
            valueListenable: _storage.wishlistNotifier,
            builder: (context, wishlist, _) {
              final isWishlisted = wishlist.contains(benefit.id);
              return IconButton(
                icon: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: isWishlisted ? Colors.redAccent : null,
                ),
                onPressed: () => _storage.toggleWishlist(benefit.id),
                tooltip: '찜하기',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Text(
                    benefit.category,
                    style: const TextStyle(
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (benefit.isNationwide) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Text(
                      '전국',
                      style: TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    benefit.organization,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ValueListenableBuilder<Map<String, int>>(
                  valueListenable: _storage.viewCountNotifier,
                  builder: (context, counts, _) {
                    final count = counts[benefit.id] ?? 0;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_outlined,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(width: 3),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              benefit.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.accentPurple),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_targetSummary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '신청 마감일',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: AppColors.accentPurple),
                const SizedBox(width: 8),
                Text(
                  benefit.endDate != null
                      ? '${benefit.endDate!.year}년 ${benefit.endDate!.month}월 ${benefit.endDate!.day}일'
                      : '상시 모집 (또는 예산 소진 시 마감)',
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '혜택 안내',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              benefit.description,
              style: const TextStyle(height: 1.6),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _openOriginalSite,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('원본 사이트에서 신청하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}