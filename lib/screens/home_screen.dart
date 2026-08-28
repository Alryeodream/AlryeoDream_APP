import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/benefit_provider.dart';
import '../../models/benefit.dart';
import '../../data/storage_service.dart';
import '../widgets/custom_date_range_picker_dialog.dart';
import '../../core/constants/regions.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/benefit_card.dart';
import '../widgets/home/home_search_filter_sheet.dart';
import '../widgets/home/home_search_bar.dart';
import '../widgets/home/home_sort_option_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService.instance;

  // Remove _allBenefits since it's from provider now

  // 통합 검색 필터 상태: 다중 선택
  final Set<String> _selectedRegions = {};
  final Set<String> _selectedCategories = {};

  // 정렬 기준: 최신순 / 조회수순 / 카테고리순 (바로 탭 가능한 퀵 필터)
  BenefitSortOption _sortOption = BenefitSortOption.latest;

  List<String> get _allCategories {
    final benefits = context.read<BenefitProvider>().benefits;
    final list = benefits.isNotEmpty ? benefits : demoBenefits;
    return list.map((b) => b.category).toSet().toList();
  }

  bool get _hasActiveFilter =>
      _selectedRegions.isNotEmpty || _selectedCategories.isNotEmpty;

  /// 선택된 지역 중 인천이 아닌 지역이 하나라도 포함되어 있는지
  /// (전국 대상 혜택은 이 경우에도 항상 노출되므로, 완전 차단이 아니라 안내 배너만 표시함)
  bool get _hasUnsupportedRegionInSelection =>
      _selectedRegions.any((r) => r != kSupportedRegion);

  late List<Benefit> _cachedFilteredBenefits;

  @override
  void initState() {
    super.initState();
    _cachedFilteredBenefits = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BenefitProvider>().fetchBenefits().then((_) {
        if (mounted) {
          setState(() {
            _updateFilteredBenefits();
          });
        }
      });
    });
  }

  void _updateFilteredBenefits() {
    final provider = context.read<BenefitProvider>();
    final allBenefits = provider.benefits.isNotEmpty ? provider.benefits : demoBenefits;

    final filtered = allBenefits.where((benefit) {
      final regionOk = _selectedRegions.isEmpty ||
          benefit.isNationwide ||
          _selectedRegions.contains(benefit.region);
      final categoryOk = _selectedCategories.isEmpty ||
          _selectedCategories.contains(benefit.category);
      return regionOk && categoryOk;
    }).toList();

    switch (_sortOption) {
      case BenefitSortOption.latest:
        break; // 기본 등록 순서 유지
      case BenefitSortOption.viewCount:
        filtered.sort((a, b) =>
            _storage.getViewCount(b.id).compareTo(_storage.getViewCount(a.id)));
      case BenefitSortOption.category:
        filtered.sort((a, b) => a.category.compareTo(b.category));
    }

    _cachedFilteredBenefits = filtered;
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<(Set<String>, Set<String>)>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SearchFilterSheet(
        allRegions: kAllRegions,
        allCategories: _allCategories,
        initialSelectedRegions: _selectedRegions,
        initialSelectedCategories: _selectedCategories,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedRegions
          ..clear()
          ..addAll(result.$1);
        _selectedCategories
          ..clear()
          ..addAll(result.$2);
        _updateFilteredBenefits();
      });
    }
  }

  Future<void> _onTapCalendarAdd(Benefit benefit) async {
    final DateTimeRange? result = await showDialog<DateTimeRange>(
      context: context,
      builder: (_) => CustomDateRangePickerDialog(benefitTitle: benefit.title),
    );

    if (result == null) return;

    await _storage.addDateRangeEvent(
      benefit: benefit,
      start: result.start,
      end: result.end,
    );

    if (!mounted) return;
    
    final message = benefit.endDate == null 
        ? '"${benefit.title}" 일정이 캘린더에 등록되었습니다.\n(상시 혜택이므로 자동 마감 알림은 설정되지 않습니다.)'
        : '"${benefit.title}" 일정이 캘린더에 등록되었습니다.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _cachedFilteredBenefits;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SearchBarButton(
              hasActiveFilter: _hasActiveFilter,
              selectedRegions: _selectedRegions,
              selectedCategories: _selectedCategories,
              onTap: _openFilterSheet,
            ),
          ),
          if (_hasActiveFilter) _buildActiveFilterChips(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: SortOptionBar(
              current: _sortOption,
              onChanged: (option) => setState(() {
                _sortOption = option;
                _updateFilteredBenefits();
              }),
            ),
          ),
          if (_hasUnsupportedRegionInSelection)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '선택하신 지역 전용 혜택은 준비중입니다! 전국 대상 혜택은 계속 보여드려요.',
                style: TextStyle(color: AppColors.accentPurple, fontSize: 12.5),
              ),
            ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '혜택의 정보 및 일정은 공지된 내용과 상이할 수 있습니다.\n자세한 정보는 원본 사이트를 참고해주세요.',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text(
                      '조건에 맞는 혜택이 없습니다.',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.accentPurple,
                    onRefresh: () async {
                      await context.read<BenefitProvider>().fetchBenefits();
                      setState(() {
                        _updateFilteredBenefits();
                      });
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final benefit = results[index];
                        return BenefitCard(
                          benefit: benefit,
                          storage: _storage,
                          onTapCalendarAdd: () => _onTapCalendarAdd(benefit),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedRegions.isNotEmpty)
            FilterChipGroup(
              label: '지역',
              items: _selectedRegions,
              onRemove: (r) => setState(() {
                _selectedRegions.remove(r);
                _updateFilteredBenefits();
              }),
            ),
          if (_selectedRegions.isNotEmpty && _selectedCategories.isNotEmpty)
            const SizedBox(height: 6),
          if (_selectedCategories.isNotEmpty)
            FilterChipGroup(
              label: '카테고리',
              items: _selectedCategories,
              onRemove: (c) => setState(() {
                _selectedCategories.remove(c);
                _updateFilteredBenefits();
              }),
            ),
        ],
      ),
    );
  }
}

