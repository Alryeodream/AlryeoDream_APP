import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/benefit.dart';
import '../../providers/auth_provider.dart';
import '../../providers/benefit_provider.dart';
import '../../data/storage_service.dart';
import '../widgets/age_picker_sheet.dart';
import 'settings/settings_screen.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/mypage/profile_card.dart';
import '../widgets/mypage/wishlisted_benefit_tile.dart';

class MyPageScreen extends StatefulWidget {
  final VoidCallback? onGoHome;

  const MyPageScreen({super.key, this.onGoHome});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storage = StorageService.instance;
  bool _isPickingImage = false;

  Future<void> _onPickProfileImage() async {
    setState(() => _isPickingImage = true);
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, // 용량 절약을 위해 리사이징
        imageQuality: 80,
      );
      if (picked == null) return;

      final Uint8List bytes = await picked.readAsBytes();
      final String base64Image = base64Encode(bytes);

      if (!mounted) return;
      await context.read<AuthProvider>().updateProfileImage(base64Image);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진을 불러오지 못했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _onEditProfile(String currentName, int currentAge) async {
    final nameController = TextEditingController(text: currentName);
    int selectedAge = currentAge;

    final result = await showDialog<(String, int)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('프로필 정보 수정'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: '닉네임',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final picked = await showAgePickerSheet(
                      context,
                      initialAge: selectedAge,
                    );
                    if (picked != null) {
                      setDialogState(() => selectedAge = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '만 나이',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      suffixIcon: Icon(Icons.expand_more),
                    ),
                    child: Text('$selectedAge세'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .pop((nameController.text.trim(), selectedAge)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('저장'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && mounted) {
      final (nickname, age) = result;
      await context
          .read<AuthProvider>()
          .updateBasicInfo(nickname: nickname, age: age);
    }
  }

  Future<void> _onLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃할까요?'),
        content: const Text('다시 로그인하려면 소셜 계정으로 재인증이 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      // 화면 전환은 main.dart의 AuthStatus 분기가 자동으로 LoginScreen으로 되돌림.
      // 로그인 화면에서 원하는 소셜 제공자를 다시 선택하면 새 계정으로 전환됨.
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '설정',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('로그인 정보를 불러올 수 없습니다.'))
          : RefreshIndicator(
              color: AppColors.accentPurple,
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
                setState(() {});
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ProfileCard(
                  nickname: user.name,
                  age: user.age,
                  profileImageBase64: user.profileImagePath,
                  isPickingImage: _isPickingImage,
                  onTapChangePhoto: _onPickProfileImage,
                  onTapEditNickname: () => _onEditProfile(user.name, user.age),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '찜한 혜택',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<Set<String>>(
                  valueListenable: _storage.wishlistNotifier,
                  builder: (context, wishlistIds, _) {
                    final provider = context.watch<BenefitProvider>();
                    final allBenefits = provider.benefits.isNotEmpty ? provider.benefits : demoBenefits;
                    final wishlisted = _storage.getWishlistedBenefits(allBenefits);

                    if (wishlisted.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        alignment: Alignment.center,
                        child: Text(
                          '아직 찜한 혜택이 없어요.\n홈 화면에서 마음에 드는 혜택에 하트를 눌러보세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: wishlisted
                          .map((benefit) => WishlistedBenefitTile(
                                benefit: benefit,
                                onRemove: () =>
                                    _storage.toggleWishlist(benefit.id),
                                onTap: () {
                                  widget.onGoHome?.call();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '홈 화면에서 "${benefit.title}" 혜택을 확인해보세요.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Icon(Icons.manage_accounts_outlined, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '계정 관리',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.redAccent),
                        title: const Text('로그아웃', style: TextStyle(color: Colors.redAccent)),
                        onTap: _onLogout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

