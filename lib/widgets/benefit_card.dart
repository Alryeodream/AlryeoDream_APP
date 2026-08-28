import 'package:flutter/material.dart';
import '../models/benefit.dart';
import '../data/storage_service.dart';
import '../core/constants/app_colors.dart';
import '../screens/benefit_detail_screen.dart';

/// 혜택을 보여주는 공용 카드 위젯.
/// 이전에는 home_screen.dart의 _BenefitCard와 custom_search_screen.dart의
/// 인라인 ListTile, 이렇게 두 곳에서 서로 다른 스타일로 중복 구현되어 있었음.
/// 이제 이 위젯 하나로 통합해서, 두 화면 모두 동일한 카드 디자인을 사용함.
///
/// [onTapCalendarAdd]를 전달하면 '전체형'(설명 + 찜하기 + 달력추가 버튼)으로,
/// 전달하지 않으면 '간략형'(제목 + 기관/카테고리 + 화살표)으로 렌더링됨.
/// 두 경우 모두 탭하면 BenefitDetailScreen으로 이동함.
class BenefitCard extends StatelessWidget {
  final Benefit benefit;
  final StorageService storage;
  final VoidCallback? onTapCalendarAdd;

  const BenefitCard({
    super.key,
    required this.benefit,
    required this.storage,
    this.onTapCalendarAdd,
  });

  bool get _isFullStyle => onTapCalendarAdd != null;

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BenefitDetailScreen(benefit: benefit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _openDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CategoryChip(label: benefit.category),
                    if (benefit.isNationwide) ...[
                      const SizedBox(width: 6),
                      const _NationwideChip(),
                    ],
                    const SizedBox(width: 6),
                    _DeadlineChip(endDate: benefit.endDate),
                    const Spacer(),
                    ValueListenableBuilder<Map<String, int>>(
                      valueListenable: storage.viewCountNotifier,
                      builder: (context, counts, _) {
                        final count = counts[benefit.id] ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_outlined,
                                size: 14,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                            const SizedBox(width: 4),
                            Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (!_isFullStyle) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  benefit.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                if (_isFullStyle) ...[
                  Text(
                    benefit.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          benefit.organization,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ValueListenableBuilder<Set<String>>(
                            valueListenable: storage.wishlistNotifier,
                            builder: (context, wishlist, _) {
                              final isWishlisted = wishlist.contains(benefit.id);
                              return IconButton(
                                icon: Icon(
                                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                                  color: isWishlisted ? AppColors.wishlistActive : Colors.grey.shade400,
                                  size: 26,
                                ),
                                onPressed: () => storage.toggleWishlist(benefit.id),
                                tooltip: '찜하기',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.accentPurple,
                              size: 26,
                            ),
                            onPressed: onTapCalendarAdd,
                            tooltip: '달력에 추가',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    '${benefit.organization} · ${benefit.category}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accentPurple,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NationwideChip extends StatelessWidget {
  const _NationwideChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.nationwideBadge.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '전국',
        style: TextStyle(
          color: AppColors.nationwideBadge,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DeadlineChip extends StatelessWidget {
  final DateTime? endDate;
  const _DeadlineChip({this.endDate});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;

    if (endDate == null) {
      text = '상시 모집';
      color = Colors.teal;
    } else {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final deadline = DateTime(endDate!.year, endDate!.month, endDate!.day);
      final difference = deadline.difference(today).inDays;

      if (difference < 0) {
        text = '마감됨';
        color = Colors.grey;
      } else if (difference == 0) {
        text = 'D-Day';
        color = Colors.redAccent;
      } else if (difference <= 3) {
        text = 'D-$difference';
        color = Colors.redAccent;
      } else {
        text = '${endDate!.month}/${endDate!.day} 마감';
        color = Colors.orange;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}