import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onTapSocialLogin(SocialProvider provider) async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().loginWithSocial(provider);
      // 화면 전환은 main.dart의 AuthStatus 분기(Consumer)가 자동으로 처리함
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardSurface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentPurple.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        '알려드림',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '청년을 위한 맞춤 혜택,\n지금 바로 확인해보세요',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                  ),
                ),
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      SocialLoginButton(
                        provider: SocialProvider.kakao,
                        backgroundColor: const Color(0xFFFEE500),
                        textColor: Colors.black87,
                        icon: Icons.chat_bubble,
                        enabled: !_isLoading,
                        onTap: () => _onTapSocialLogin(SocialProvider.kakao),
                      ),
                      const SizedBox(height: 12),
                      SocialLoginButton(
                        provider: SocialProvider.naver,
                        backgroundColor: const Color(0xFF03C75A),
                        textColor: Colors.white,
                        icon: Icons.chat_bubble_outline, // 네이버 아이콘이 없으므로 임시로 챗버블 사용
                        enabled: !_isLoading,
                        onTap: () => _onTapSocialLogin(SocialProvider.naver),
                      ),
                      const SizedBox(height: 12),
                      SocialLoginButton(
                        provider: SocialProvider.google,
                        backgroundColor: Colors.white,
                        textColor: Colors.black87,
                        borderColor: Colors.grey.shade300,
                        icon: Icons.g_mobiledata,
                        enabled: !_isLoading,
                        onTap: () => _onTapSocialLogin(SocialProvider.google),
                      ),
                      const SizedBox(height: 12),
                      SocialLoginButton(
                        provider: SocialProvider.guest,
                        backgroundColor: Colors.grey.shade800,
                        textColor: Colors.white,
                        icon: Icons.person_outline,
                        enabled: !_isLoading,
                        onTap: () => _onTapSocialLogin(SocialProvider.guest),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

