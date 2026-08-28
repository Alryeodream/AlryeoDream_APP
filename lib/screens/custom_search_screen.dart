import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/benefit_provider.dart';
import '../../models/benefit.dart';
import '../../data/storage_service.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/regions.dart';
import '../widgets/age_picker_sheet.dart';
import '../widgets/benefit_card.dart';

class CustomSearchScreen extends StatefulWidget {
  const CustomSearchScreen({super.key});

  @override
  State<CustomSearchScreen> createState() => _CustomSearchScreenState();
}

class _CustomSearchScreenState extends State<CustomSearchScreen> {

  final StorageService _storage = StorageService.instance;

  int? _age;
  String _gender = '무관';
  String _region = kAllRegions.first;
  bool _initializedFromProfile = false;
  BenefitSortOption _sortOption = BenefitSortOption.latest;

  List<Benefit> _sortedBenefits = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 회원가입 당시 등록한 나이를 기본값으로 세팅 (최초 1회만)
    if (!_initializedFromProfile) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        _age = user.age;
      }
      _initializedFromProfile = true;
    }
  }

  Future<void> _onTapAgeField() async {
    final picked = await showAgePickerSheet(
      context,
      initialAge: _age ?? 24,
    );
    if (picked != null) {
      setState(() => _age = picked);
    }
  }

  Future<void> _onSubmit() async {
    if (_age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('나이를 선택해주세요.')),
      );
      return;
    }

    // Since we are connected to the API, we can either call the custom endpoint or use local filtering.
    // We already have a /benefits/custom endpoint, but since the user can change age/gender/region in the UI, 
    // we should filter locally based on the fetched benefits, or send these as query params. 
    // The backend /benefits/custom uses the user's DB profile. 
    // Since the UI allows tweaking without saving, we will filter locally using all benefits.
    final provider = context.read<BenefitProvider>();
    List<Benefit> allBenefits = provider.benefits;
    if (allBenefits.isEmpty) {
      await provider.fetchBenefits();
      allBenefits = provider.benefits;
      if (allBenefits.isEmpty) allBenefits = demoBenefits;
    }

    final isRegionSupported = _region == kSupportedRegion;
    final matched = allBenefits.where((benefit) {
      final regionOk = benefit.matchesRegion(_region);
      final conditionOk = benefit.matches(age: _age!, gender: _gender);
      return regionOk && conditionOk;
    }).toList();

    setState(() {
      _result = isRegionSupported; // boolean now
      _matchedBenefits = matched;
      _updateSortedBenefits();
    });

    if (!isRegionSupported && matched.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('준비중입니다!')),
      );
    }
  }

  bool? _result;
  List<Benefit> _matchedBenefits = [];

  void _updateSortedBenefits() {
    if (_result == null || _matchedBenefits.isEmpty) {
      _sortedBenefits = [];
      return;
    }
    final list = List<Benefit>.from(_matchedBenefits);
    switch (_sortOption) {
      case BenefitSortOption.latest:
        break;
      case BenefitSortOption.viewCount:
        list.sort((a, b) =>
            _storage.getViewCount(b.id).compareTo(_storage.getViewCount(a.id)));
      case BenefitSortOption.category:
        list.sort((a, b) => a.category.compareTo(b.category));
    }
    _sortedBenefits = list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('맞춤검색'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 나이: 스크롤 휠 피커로 선택 (회원가입 당시 나이가 기본값)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _onTapAgeField,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: '만 나이',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  suffixIcon: Icon(Icons.expand_more),
                ),
                child: Text(_age != null ? '$_age세' : '나이를 선택해주세요'),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: InputDecoration(
                labelText: '성별',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              items: const ['무관', '남', '여']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _gender = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _region,
              // 지역이 17개나 되어 팝업이 화면 전체를 덮지 않도록 높이 제한
              menuMaxHeight: 320,
              decoration: InputDecoration(
                labelText: '거주 지역',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              items: kAllRegions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _region = value);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _onSubmit,
              child: const Text('나에게 맞는 혜택 찾기'),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildResultArea()),
          ],
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    if (_result == null) {
      return const SizedBox.shrink();
    }

    if (_matchedBenefits.isEmpty) {
      return const Center(
        child: Text(
          '조건에 맞는 혜택이 없습니다.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final sortedBenefits = _sortedBenefits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 조회수순 / 카테고리순 / 최신순 — 한 번의 탭으로 바로 전환 가능한 정렬 필터
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: BenefitSortOption.values.map((option) {
              final selected = option == _sortOption;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(option.label, style: const TextStyle(fontSize: 12.5)),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _sortOption = option;
                    _updateSortedBenefits();
                  }),
                  selectedColor: AppColors.accentPurple.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.accentPurple : null,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.accentPurple : Theme.of(context).dividerColor,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            }).toList(),
          ),
        ),
        if (!_result!)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '선택하신 지역 전용 혜택은 준비중입니다! 전국 대상 혜택만 보여드려요.',
              style: TextStyle(color: AppColors.accentPurple, fontSize: 12.5),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.accentPurple,
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
              setState(() {
                _updateSortedBenefits();
              });
            },
            child: ListView.separated(
              itemCount: sortedBenefits.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final benefit = sortedBenefits[index];
                return BenefitCard(
                  benefit: benefit,
                  storage: _storage,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}