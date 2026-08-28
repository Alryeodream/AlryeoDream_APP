import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/age_picker_sheet.dart';
import '../../../core/constants/app_colors.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  int? _age;

  bool _nightConsent = false;
  bool _isSendingCode = false;
  bool _codeSent = false;
  String? _codeError;
  String? _emailError;

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _age = user.age;
      _emailController.text = user.email;
      _nightConsent = user.nightNotificationConsent;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _onSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      setState(() => _emailError = '올바르지 않은 형식입니다. (예: example@email.com)');
      return;
    }

    setState(() {
      _emailError = null;
      _isSendingCode = true;
      _codeError = null;
    });

    await context
        .read<AuthProvider>()
        .sendVerificationEmail(_emailController.text.trim());

    if (!mounted) return;
    setState(() {
      _isSendingCode = false;
      _codeSent = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('인증 코드가 발송되었습니다. (테스트 환경: 콘솔 로그 확인)')),
    );
  }

  void _onVerifyCode() {
    final success =
        context.read<AuthProvider>().verifyEmailCode(_codeController.text);
    setState(() {
      _codeError = success ? null : '인증 코드가 일치하지 않습니다.';
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 인증이 완료되었습니다.')),
      );
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    /* 개발 단계 임시 주석 처리 (이메일 인증 패스)
    if (!auth.user!.emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 인증을 먼저 완료해주세요.')),
      );
      return;
    }
    */

    if (_age == null || _age! <= 0 || _age! > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('나이를 올바르게 선택해주세요.')),
      );
      return;
    }

    await auth.updateProfile(
      name: _nameController.text.trim(),
      age: _age!,
      nightNotificationConsent: _nightConsent,
    );
    // 화면 전환은 main.dart의 AuthStatus 분기가 자동 처리 (emailVerified true가 되는 순간 전환됨)
  }

  Future<void> _onBack() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원가입을 취소할까요?'),
        content: const Text('지금까지 입력한 내용이 저장되지 않고, 로그인 화면으로 돌아갑니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('계속 진행'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('취소하고 나가기'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      // 화면 전환은 main.dart의 AuthStatus 분기가 자동으로 LoginScreen으로 되돌림
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '뒤로가기',
          onPressed: _onBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '닉네임',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? '닉네임을 입력해주세요.' : null,
              ),
              const SizedBox(height: 16),

              // 나이 입력: 탭하면 스크롤 휠 피커로 선택 (숫자와 '세'가 붙어서 표시됨)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final picked = await showAgePickerSheet(
                    context,
                    initialAge: _age ?? 24,
                  );
                  if (picked != null) {
                    setState(() => _age = picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '만 나이',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    suffixIcon: const Icon(Icons.expand_more),
                  ),
                  child: Text(_age != null ? '$_age세' : '나이를 선택해주세요'),
                ),
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 24),
              /* 개발 단계 임시 주석 처리 (이메일 인증)
              Text(
                '이메일 인증',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      enabled: user?.emailVerified != true,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: '이메일 주소',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        errorText: _emailError,
                      ),
                      onChanged: (value) {
                        if (_emailError == null) return;
                        // 입력 중 형식이 맞춰지면 에러 메시지 즉시 해제
                        if (value.isEmpty || _emailRegex.hasMatch(value)) {
                          setState(() => _emailError = null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (user?.emailVerified == true || _isSendingCode)
                          ? null
                          : _onSendCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSendingCode
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(user?.emailVerified == true ? '인증완료' : '코드 발송'),
                    ),
                  ),
                ],
              ),
              if (_codeSent && user?.emailVerified != true) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '인증 코드 6자리',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          errorText: _codeError,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _onVerifyCode,
                        child: const Text('확인'),
                      ),
                    ),
                  ],
                ),
              ],
              if (user?.emailVerified == true) ...[
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 6),
                    Text('이메일 인증이 완료되었습니다.',
                        style: TextStyle(color: Colors.green)),
                  ],
                ),
              ],
              */

              const SizedBox(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('심야 알림 수신 동의'),
                subtitle: const Text('21시~08시에도 마감 임박 혜택 알림을 받습니다.'),
                value: _nightConsent,
                activeThumbColor: AppColors.accentPurple,
                onChanged: (value) => setState(() => _nightConsent = value),
              ),

              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _onSubmit,
                  child: const Text('가입 완료하고 시작하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}