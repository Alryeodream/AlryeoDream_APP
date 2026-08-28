import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/legal_terms_content.dart';
import '../../../core/constants/app_colors.dart';

/// 이용약관 및 개인정보 처리방침을 끝까지 스크롤해야만
/// '동의하고 계속하기' 버튼이 활성화되는 화면.
class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToEnd = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // 내용이 짧아 스크롤이 필요 없는 화면 크기일 경우를 대비해
    // 최초 렌더링 후 한 번 체크
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isAtBottom = position.pixels >= (position.maxScrollExtent - 16);
    // 콘텐츠가 뷰포트보다 짧아서 스크롤 자체가 불가능한 경우도 '끝까지 읽음'으로 처리
    final noScrollNeeded = position.maxScrollExtent == 0;

    if ((isAtBottom || noScrollNeeded) && !_hasScrolledToEnd) {
      setState(() => _hasScrolledToEnd = true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onAgree() async {
    await context.read<AuthProvider>().agreeToTerms();
    // 화면 전환은 main.dart의 AuthStatus 분기가 자동 처리
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용약관 동의'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          if (!_hasScrolledToEnd)
            Container(
              width: double.infinity,
              color: AppColors.accentPurple.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: const Text(
                '약관 내용을 끝까지 읽어주셔야 동의할 수 있습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.accentPurple, fontSize: 13),
              ),
            ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: const LegalTermsContent(),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _hasScrolledToEnd ? _onAgree : null,
                  child: Text(
                    _hasScrolledToEnd ? '동의하고 계속하기' : '끝까지 읽어주세요',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}