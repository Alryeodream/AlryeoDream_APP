import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// 홈 화면 상단, 탭하면 필터 시트가 열리는 검색창 형태의 버튼
class SearchBarButton extends StatelessWidget {
  final bool hasActiveFilter;
  final Set<String> selectedRegions;
  final Set<String> selectedCategories;
  final VoidCallback onTap;

  const SearchBarButton({
    super.key,
    required this.hasActiveFilter,
    required this.selectedRegions,
    required this.selectedCategories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = selectedRegions.length + selectedCategories.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.search, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasActiveFilter
                        ? '지역 · 카테고리 $totalCount개 선택됨'
                        : '관심 지역 · 카테고리로 혜택 검색',
                    style: TextStyle(
                      color: hasActiveFilter
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.grey.shade500,
                      fontWeight: hasActiveFilter ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.tune, color: AppColors.accentPurple, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

