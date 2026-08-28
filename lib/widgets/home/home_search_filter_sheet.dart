import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// "지역" / "카테고리" 라벨과 함께 선택된 칩들을 한 줄로 묶어 보여주는 그룹
class FilterChipGroup extends StatelessWidget {
  final String label;
  final Set<String> items;
  final ValueChanged<String> onRemove;

  const FilterChipGroup({
    super.key,
    required this.label,
    required this.items,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: items
                .map((item) => ActiveFilterChip(
                      label: item,
                      onRemove: () => onRemove(item),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const ActiveFilterChip({super.key, required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onDeleted: onRemove,
      backgroundColor: AppColors.accentPurple.withValues(alpha: 0.1),
      deleteIconColor: AppColors.accentPurple,
      labelStyle: const TextStyle(color: AppColors.accentPurple),
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// 지역(17개 시도) / 카테고리 다중 선택 바텀시트
class SearchFilterSheet extends StatefulWidget {
  final List<String> allRegions;
  final List<String> allCategories;
  final Set<String> initialSelectedRegions;
  final Set<String> initialSelectedCategories;

  const SearchFilterSheet({
    super.key,
    required this.allRegions,
    required this.allCategories,
    required this.initialSelectedRegions,
    required this.initialSelectedCategories,
  });

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late Set<String> _regions;
  late Set<String> _categories;

  @override
  void initState() {
    super.initState();
    _regions = Set<String>.from(widget.initialSelectedRegions);
    _categories = Set<String>.from(widget.initialSelectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '혜택 검색 필터',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _regions.clear();
                      _categories.clear();
                    }),
                    child: const Text('초기화'),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const SizedBox(height: 8),
                    Text('관심 지역 (다중 선택 가능)',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.allRegions.map((region) {
                        final selected = _regions.contains(region);
                        return FilterChip(
                          label: Text(region),
                          selected: selected,
                          selectedColor: AppColors.accentPurple.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.accentPurple,
                          labelStyle: TextStyle(
                            color: selected ? AppColors.accentPurple : null,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          onSelected: (value) => setState(() {
                            if (value) {
                              _regions.add(region);
                            } else {
                              _regions.remove(region);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text('카테고리 (다중 선택 가능)',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.allCategories.map((category) {
                        final selected = _categories.contains(category);
                        return FilterChip(
                          label: Text(category),
                          selected: selected,
                          selectedColor: AppColors.accentPurple.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.accentPurple,
                          labelStyle: TextStyle(
                            color: selected ? AppColors.accentPurple : null,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          onSelected: (value) => setState(() {
                            if (value) {
                              _categories.add(category);
                            } else {
                              _categories.remove(category);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop((_regions, _categories));
                  },
                  child: const Text('적용하기'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
