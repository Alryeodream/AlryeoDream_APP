import 'package:flutter/material.dart';
import '../../../../models/benefit.dart';
import '../../../../core/constants/app_colors.dart';

/// 조회수순 / 카테고리순 / 최신순을 한 번의 탭으로 바로 전환하는 정렬 바
class SortOptionBar extends StatelessWidget {
  final BenefitSortOption current;
  final ValueChanged<BenefitSortOption> onChanged;

  const SortOptionBar({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: BenefitSortOption.values.map((option) {
          final selected = option == current;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(option.label, style: const TextStyle(fontSize: 12.5)),
              selected: selected,
              onSelected: (_) => onChanged(option),
              selectedColor: AppColors.accentPurple.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: selected ? AppColors.accentPurple : null,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: selected
                    ? AppColors.accentPurple
                    : Theme.of(context).dividerColor,
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }
}
